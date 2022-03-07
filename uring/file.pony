use "files"
use "debug"
use "itertools"

use @ponyint_o_rdonly[I32]()
use @open[I32](path: Pointer[U8] tag, flags: I32, mode: U32) if not windows
use @pony_os_errno[I32]()

primitive Abort
class val Continue
  let _offset: (None | U64)

  new val create(offset': (None | U64) = None) =>
    _offset = offset'

  fun offset(): (None | U64) =>
    _offset

type ControlFlow is (Abort | Continue)

interface iso FileReaderNotify
  fun ref on_data(data: Array[U8] iso, offset: U64): ControlFlow
  fun ref on_eof()
  fun ref on_close()
  fun ref on_err(errno: I32)

class val FileReaderConfig
  """
  Configuration for the FileReader.
  """
  let path: FilePath
  let chunk_size: USize
    """
    Size of the chunks to receive data in.

    This will determine the amount of memory allocated at the same time
    by doing `chunk_size * nr_chunks`.
    """
  let nr_chunks: USize
    """
    Number of chunks to receive the data in.

    This will determine the amount of memory allocated at the same time
    by doing `chunk_size * nr_chunks`.
    """

  let offset: U64
    """
    Offset at which to start reading.
    """

  new val create(path': FilePath, offset': U64 = 0, chunk_size': USize = 4096, nr_chunks': USize = 10) =>
    path = path'
    offset = offset'
    chunk_size = chunk_size'
    nr_chunks = nr_chunks'


actor FileReader is URingNotify
  """
  A File backed by io_uring for real asynchronous reading on linux (at least).
  """
  let _config: FileReaderConfig
  let _uring: URing
  let _notify: FileReaderNotify ref

  var _offset: U64
  var _fd: I32
  var _err: (I32 | None) = None

  new create(config: FileReaderConfig, uring: URing, notify: FileReaderNotify iso) =>
    ifdef linux then
      _config = config
      _offset = _config.offset
      _uring = uring
      _notify = consume notify

      let mode = FileMode.u32()
      let flags: I32 = @ponyint_o_rdonly()
      _fd = @open(_config.path.path.cstring(), flags, mode)
      if _fd == -1 then
        _notify.on_err(@pony_os_errno())
      else
        _initiate_read()
      end
    else
      // TODO: fall back to normal files for all other systems than linux
      compile_error "uring only supported on linux"
    end

  fun ref _initiate_read() =>
    """
    Allocate all chunks and do a readv.
    """
    let sizes =
      recover val Iter[USize]
        .repeat_value(_config.chunk_size)
        .take(_config.nr_chunks)
        .collect(Array[USize](_config.nr_chunks))
      end

    let op = OpReadv.create(sizes, _fd, _offset)
    let that: URingNotify tag = this
    _uring.submit(consume op, that)

  fun ref _initiate_close() =>
    let op = OpClose.create(_fd)
    let that: URingNotify tag = this
    _uring.submit(consume op, that)

  be op_completed(op: URingOp iso, result: I32) =>
    // TODO: close the file automatically here
    match consume op
    | let close': OpClose iso =>
      _fd = -1
      if result == 0 then
        _notify.on_close()
      else
        _notify.on_err(@pony_os_errno())
      end
    | let readv: OpReadv iso =>
      if result > 0 then
        var bytes_left: USize = result.usize()
        var offset = readv.offset()
        var flow: ControlFlow = Continue
        let bufs = (consume readv).extract_buf()

        while (bufs.size() > 0) do
          try
            let buf = bufs.shift()?
            let buf_size = buf.size()
            let current_offset = offset = offset + buf_size.u64()
            if bytes_left < buf_size then
              // we have a short read
              buf.truncate(bytes_left)
              match _notify.on_data(consume buf, current_offset)
              | let c: Continue =>
                let continue_offset = c.offset()
                match continue_offset
                | let c_offset: U64 =>
                  flow = Continue
                  _offset = c_offset
                else
                  flow = Abort
                  _notify.on_eof()
                  break
                end
              | Abort =>
                flow = Abort
                _notify.on_eof()
                break
              end
            else
              match _notify.on_data(consume buf, current_offset)
              | Abort =>
                flow = Abort
                break
              | let c: Continue =>
                flow = Continue
                _offset = Iter[U64].maybe(c.offset()).next_or(offset)
                bytes_left = bytes_left - buf_size
              end
            end
          end
        end
        match flow
        | let c: Continue =>
          _initiate_read()
        | Abort =>
          _initiate_close()
        end
      elseif result == 0 then
        _notify.on_eof()
        _initiate_close()
      else
        _notify.on_err(result)
        _initiate_close()
      end
    end

  be failed(op: URingOp) =>
    _notify.on_err(@pony_os_errno())
    _initiate_close()


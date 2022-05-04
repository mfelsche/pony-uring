use "files"
use "debug"
use "itertools"

use @lseek64[I64](fd: I32, offset: I64, base: I32) if linux
use @pony_os_errno[I32]()

interface ErrorNotify
  fun ref on_err(errno: I32)

actor FileInputStream is (URingNotify & InputStream)
  """
  A File backed by io_uring for real asynchronous reading on linux (at least).
  """
  let _uring: URing
  let _path: FilePath
  var _error_notify: (ErrorNotify iso | None)
  let _start_offset: U64

  var _input_notify: (InputNotify iso | None)
  var _chunk_size: USize
  var _offset: U64
  var _fd: I32

  new create(
    path': FilePath,
    uring': URing,
    offset': U64 = 0,
    chunk_size': USize = 4096,
    input_notify: (InputNotify iso | None) = None,
    error_notify: (ErrorNotify iso | None) = None) =>
    ifdef linux then
      _uring = uring'
      _path = path'
      _start_offset = offset'
      _input_notify = consume input_notify
      _error_notify = consume error_notify

      _chunk_size = chunk_size'
      _offset = offset'
      _fd = -1 // dummy value

      // only open the file if we have a notify
      // otherwise we do nothing until `apply` is called.
      if _input_notify isnt None then
        _initiate_open()
      end
    else
      // TODO: fall back to normal files for all other systems than linux
      compile_error "uring only supported on linux"
    end

  fun ref _notify_err(errno: I32) =>
    try
      (_error_notify as ErrorNotify iso).on_err(-1)
    end

  fun ref _initiate_open() =>
    try
      let op = OpOpenat.read_only(_path)?
      let that: URingNotify tag = this
      _uring.submit_op(consume op, that)
    else
      _notify_err(-1)
    end

  fun ref _initiate_reopen() =>
    """
    do a linked close, then open
    """
    try
      let ops: Array[URingOp iso] iso =
        recover iso
          [
            OpClose.create(_fd, recover val SQEFlags.add(SQELink) end)
            OpOpenat.read_only(_path)?
          ]
        end
      let that: URingNotify tag = this
      _uring.submit_ops(consume ops, that)
    else
      _notify_err(-1)
    end

  fun ref _initiate_read() =>
    """
    Allocate a chunk and request a readv from the uring.
    """
    let buf: Array[U8] iso =
      recover iso
        Array[U8] .> undefined(_chunk_size)
      end

    let op = OpReadv.from_single_buf(consume buf, _fd, _offset)
    let that: URingNotify tag = this
    _uring.submit_op(consume op, that)

  fun ref _initiate_close() =>
    let op = OpClose.create(_fd)
    let that: URingNotify tag = this
    _uring.submit_op(consume op, that)

  be op_completed(op: URingOp iso, result: I32) =>
    match consume op
    | let openat': OpOpenat iso =>
      _fd = result
      _offset = _start_offset
      if result == -1 then
        _notify_err(@pony_os_errno())
      elseif _input_notify isnt None then
        _initiate_read()
      end
    | let close': OpClose iso =>
      _fd = -1
      if result != 0 then
        _notify_err(@pony_os_errno())
      end
    | let readv: OpReadv iso =>
      if result > 0 then
        var bytes_left: USize = result.usize()
        let bufs = (consume readv).extract_buf()

        while (bufs.size() > 0) do
          try
            let buf = bufs.shift()?
            let buf_size = buf.size()
            _offset = _offset + buf_size.u64()
            if bytes_left < buf_size then
              // we have a short read
              buf.truncate(bytes_left)
              try
                (_input_notify as InputNotify).apply(consume buf)
              end
            else
              try
                (_input_notify as InputNotify).apply(consume buf)
              end
            end
            bytes_left = bytes_left - buf_size
          end
        end
        // only initiate a new read if we have an input notify
        if _input_notify isnt None then
          _initiate_read()
        end
      elseif result == 0 then
        // EOF
        _initiate_close()
        try
          (_input_notify as InputNotify).dispose()
        end
      else
        _notify_err(result)
        _initiate_close()
        try
          (_input_notify as InputNotify).dispose()
        end
      end
    end

  be failed(op: URingOp) =>
    """
    a uring operation failed
    """
    _notify_err(@pony_os_errno())
    if _fd != -1 then
      _initiate_close()
      try
        (_input_notify as InputNotify).dispose()
      end
    end

  be apply(notify: (InputNotify iso | None), chunk_size: USize = 32) =>
    """
    Set the notifier. Optionally, also sets the chunk size, dictating the
    maximum number of bytes of each chunk that will be passed to the notifier.

    Setting `notify` to `None` will effectively close the file stream.

    Setting `notify` to a new `InputNotify` will re-read the file from the `offset`
    configured upon creation.
    """
    _chunk_size = chunk_size
    _set_notify(consume notify)


  be dispose() =>
    """
    Clear the notifier in order to shut down input.
    """
    _set_notify(None)

  fun ref _set_notify(notify: (InputNotify iso | None)) =>
    if (notify is None) and (_input_notify isnt None) then
      // set existing notify to None and dispose of the old one
      try
        ((_input_notify = None) as InputNotify).dispose()
      end
      // we gotta close the file
      // so we keep the invariant that no notify means closed file
      if _fd != -1 then
        _initiate_close()
      end
    elseif (notify isnt None) and (_input_notify is None) then
      // we go from None to a new notify
      _input_notify = consume notify
      // open the file to stream through the file again
      _initiate_open()
    elseif (notify isnt None) and (_input_notify isnt None) then

      try
        ((_input_notify = consume notify) as InputNotify).dispose()
      end
      // we replace an existing notify with another one
      // we need to close and reopen the file
      _initiate_reopen()
    else
      // it remains None, nothing left to do
      None
    end

  be set_err_notify(err_notify: (ErrorNotify iso | None)) =>
    _error_notify = consume err_notify

class FileOutStream
  """
  Builder for a URingOutStream backed by a file
  """
  fun tag apply(
    path: FilePath,
    uring: URing,
    // TODO: create a flags instance for our file
    flags: I32 = @ponyint_o_rdwr() or @ponyint_o_creat() or @ponyint_o_trunc()
  ): URingOutStream ? =>
    """
    Build yourself a nice little FileOutStream
    """
    let op = OpOpenat.create(path where flags' = flags)?
    URingOutStream._from_file(path, flags, consume op, uring)

actor URingOutStream is (URingNotify & OutStream)
  """
  URing backed OutStream implementation

  that can be used on regular files or stdout/stdin.
  """
  let _path: (FilePath | None)
    """
    Maybe used for error reporting in the future
    """
  let _uring: URing
  let _open_flags: I32

  var _offset: U64 = 0
  var _fd: I32 = -2
    """
    -2    -> not yet initialized
    -1    -> failed to open or closed.
    >= 0  -> valid fd
    """
  var _pending_ops: Array[URingOp iso] iso = recover iso _pending_ops.create(0) end
    """
    if we are not yet open, but already received calls to print/write etc
    we need to queue operations until we have an fd ready.
    """

  new _from_file(
    path: FilePath,
    open_flags: I32,
    op: OpOpenat,
    uring: URing
    ) =>
      _path = path
      _uring = uring
      _open_flags = open_flags
      // initiate open
      let notify: URingNotify tag = this
      _uring.submit_op(consume op, notify)

  new stdout(uring: URing) =>
    _path = None
    _uring = uring
    _open_flags = 0
    _fd = 1

  new stderr(uring: URing) =>
    _path = None
    _uring = uring
    _open_flags = 0
    _fd = 1

  be print(data: ByteSeq) =>
    """
    Print some bytes and insert a newline afterwards.
    """
    let byteseqiter: Array[ByteSeq] val = if data.size() == 0 then
      ["\n"]
    else
      [data; "\n"]
    end
    _writev(byteseqiter)

  be write(data: ByteSeq) =>
    """
    Print some bytes without inserting a newline afterwards.
    """
    if data.size() > 0 then
      let byteseqiter: Array[ByteSeq] val = [data]
      _writev(byteseqiter)
    end

  be printv(data: ByteSeqIter) =>
    """
    Print an iterable collection of ByteSeqs.
    """
    _writev(_PrintIter.create(data))


  be writev(data: ByteSeqIter) =>
    """
    Write an iterable collection of ByteSeqs.
    """
    _writev(data)

  fun ref _writev(data: ByteSeqIter) =>
    if _fd >= 0 then
      let op = OpWritev.create(_fd, data, _offset)
      _offset = _offset + op.num_bytes().u64()
      let notify: URingNotify = this
      _uring.submit_op(consume op, notify)
    elseif _fd == -2 then
      let op = OpWritev.create(_fd, data, _offset)
      // don't increase offset here intentionally
      // this is done in _submit_pending_ops
      _pending_ops.push(consume op)
    end

  be flush() =>
    """
    Flush the stream.
    """
    if _fd >= 0 then
      let op = OpFsync.create(_fd)
      let notify: URingNotify = this
      _uring.submit_op(consume op, notify)
    elseif _fd == -2 then
      let op = OpFsync.create(_fd)
      _pending_ops.push(consume op)
    end

  be close() =>
    """
    Close the stream.
    """
    if _fd > 2 then // don't allow closing stdout or stderr
      let op = OpClose.create(_fd)
      let notify: URingNotify = this
      _uring.submit_op(consume op, notify)
    elseif _fd == -2 then
      let op = OpClose.create(_fd)
      _pending_ops.push(consume op)
    end
    // set fd to -1 already here, so no operation after this one
    // fails at the uring step (because of an already close fd)
    _fd = -1

  be op_completed(op: URingOp iso, result: I32) =>
    match consume op
    | let openat': OpOpenat iso =>
      _fd = result
      if result != -1 then
        _offset = _get_current_offset()
        _submit_pending_ops()
      end
    | let close': OpClose iso =>
      _fd = -1 // necessary in case we get here via _pending_ops
    | let fsync': OpFsync iso =>
      // TODO: notify about error
      None
    | let writev': OpWritev iso =>
      // TODO: notify about error -> How?
      None
    end

  be failed(op: URingOp) => None

  fun ref _submit_pending_ops() =>
    """
    If we got called before the file was actually opened,
    we need to queue up operations until we got an actual fd.

    Only then can we submit the pending operations and add the correct fd.
    """
    if _pending_ops.size() > 0 then
      // recreate array with correct fds set
      let pending_ops =
        recover iso
          Array[URingOp iso].create(_pending_ops.size())
        end
      while _pending_ops.size() > 0 do
        try
          match _pending_ops.shift()?
          | let op: OpWritev iso =>
            op.set_fd(_fd)
            // set offset and increase by the number of bytes to be written
            op.set_offset(_offset = _offset + op.num_bytes().u64())
            pending_ops.push(consume op)
          | let op: OpFsync iso =>
            op.set_fd(_fd)
            pending_ops.push(consume op)
          | let op: OpClose iso =>
            op.set_fd(_fd)
            pending_ops.push(consume op)
          end
        end
      end
      // send pending ops
      let notify: URingNotify tag = this
      _uring.submit_ops(consume pending_ops, notify)
    end

  fun ref _get_current_offset(): U64 =>
    if _fd >= 0 then
      let o: I64 = 0
      let b: I32 = 1
      let r = ifdef linux then
        @lseek64(_fd, o, b)
      else
        0
      end
      r.u64()
    else
      0
    end

class val _PrintIter is ByteSeqIter
  let _iter: ByteSeqIter
  new val create(iter: ByteSeqIter) =>
    _iter = iter

  fun values(): Iterator[this->ByteSeq box] =>
    Iter[this->ByteSeq box].create(_iter.values()).intersperse("\n")

use "files"
use @ponyint_o_rdwr[I32]()
use @ponyint_o_creat[I32]()
use @ponyint_o_trunc[I32]()
use @ponyint_o_rdonly[I32]()

// TODO: make SQEFlags part of every op
type URingOp is ((OpNop | OpRead | OpReadv | OpWritev | OpOpenat | OpClose | OpFsync) & HasOpKind iso & HasSQEFlags iso)

interface HasOpKind
  fun kind(): OpKind

interface HasSQEFlags
  fun sqe_flags(): SQEFlags

class iso OpNop
  let _sqe_flags: SQEFlags

  new iso create(sqe_flags': SQEFlags = SQEFlags) =>
    _sqe_flags = sqe_flags'

  fun kind(): OpKind => OpKindNop
  fun sqe_flags(): SQEFlags => _sqe_flags

class iso OpRead
  var _buf: Array[U8] iso
  var _ptr: Pointer[U8] tag
  var _nbytes: U32
  let _fd: I32
  let _offset: U64
  let _sqe_flags: SQEFlags

  new iso create(buf': Array[U8] iso, fd': I32, offset': U64, sqe_flags': SQEFlags = SQEFlags) =>
    _ptr = buf'.cpointer()
    _nbytes = buf'.size().u32()
    _buf = consume buf'
    _fd = fd'
    _offset = offset'
    _sqe_flags = sqe_flags'

  fun kind(): OpKind => OpKindRead
  fun sqe_flags(): SQEFlags => _sqe_flags

  fun fd(): I32 => _fd
  fun offset(): U64 => _offset
  fun buf(): Pointer[U8] tag => _ptr
  fun nbytes(): U32 => _nbytes

class iso OpReadv
  """
  readv Operation

  TODO: Find a better way for reusing this class for multiple readv calls.
  """
  var _buf: Array[Array[U8] iso] iso
    """
    The actual buffers to be filled
    """
  var _ptr: Array[(Pointer[U8] tag, USize)] val
    """
    iovec array derived from the above buffers for passing across the FFI boundary
    """

  let _fd: I32
  let _sqe_flags: SQEFlags
  var _offset: U64

  new iso create(buf_sizes: Array[USize] val, fd': I32, offset': U64 = 0, sqe_flags': SQEFlags = SQEFlags) =>
    """
    Create a new readv operation with a descriptor of the iovec sizes.
    The iovec buffers will be freshly allocated.
    """
    let ptr = recover trn Array[(Pointer[U8] tag, USize)].create(buf_sizes.size()) end
    let buf = recover iso Array[Array[U8] iso].create(buf_sizes.size()) end
    for buf_size in buf_sizes.values() do
      let arr = recover iso Array[U8] .> undefined(buf_size) end
      ptr.push(
        (arr.cpointer(), arr.size())
      )
      buf.push(consume arr)
    end
    _ptr = consume ptr
    _buf = consume buf
    _fd = fd'
    _offset = offset'
    _sqe_flags = sqe_flags'

  new iso from_single_buf(buf: Array[U8] iso, fd': I32, offset': U64 = 0, sqe_flags': SQEFlags = SQEFlags) =>
    """
    """
    let ptr = recover trn Array[(Pointer[U8] tag, USize)].create(1) end
    let bufs = recover iso Array[Array[U8] iso].create(1) end
    ptr.push((buf.cpointer(), buf.size()))
    bufs.push(consume buf)

    _ptr = consume ptr
    _buf = consume bufs
    _fd = fd'
    _offset = offset'
    _sqe_flags = sqe_flags'


  fun kind(): OpKind => OpKindReadv
  fun sqe_flags(): SQEFlags => _sqe_flags

  fun iovec(): Pointer[(Pointer[U8] tag, USize)] tag => _ptr.cpointer()
  fun numvecs(): U32 => _ptr.size().u32()
  fun fd(): I32 => _fd
  fun offset(): U64 => _offset
  fun ref set_offset(new_offset: U64) => _offset = new_offset
  fun ref advance_offset(delta: U64) => _offset = _offset + delta


  fun iso extract_buf(): Array[Array[U8] iso] iso^ =>
    """
    Consumes this instance and extracts the internal buffer.

    Take care to get the offset and fd beforehand otherwise they are gone
    when this function returns.
    """
    // reset internal buffers to empty
    let buf = _buf = recover Array[Array[U8] iso].create(0) end
    _ptr = recover val Array[(Pointer[U8] tag, USize)].create(0) end
    consume buf


class iso OpWritev
  let _iovec: Array[(Pointer[U8] tag, USize)] val

  let _sqe_flags: SQEFlags

  var _fd: I32
  var _offset: U64

  new iso create(
    fd': I32,
    seqs': ByteSeqIter,
    offset': U64,
    sqe_flags': SQEFlags = SQEFlags
  ) =>
    _fd = fd'
    _offset = offset'
    _sqe_flags = sqe_flags'

    let ptr = recover trn Array[(Pointer[U8] tag, USize)].create(1) end
    for seq in seqs'.values() do
      ptr.push((seq.cpointer(), seq.size()))
    end
    _iovec = consume ptr

  fun kind(): OpKind => OpKindWritev
  fun sqe_flags(): SQEFlags => _sqe_flags
  fun iovec(): Pointer[(Pointer[U8] tag, USize)] tag => _iovec.cpointer()
  fun numvecs(): U32 => _iovec.size().u32()
  fun offset(): U64 => _offset
  fun ref set_offset(new_offset: U64) => _offset = new_offset
  fun fd(): I32 => _fd
  fun ref set_fd(new_fd: I32) => _fd = new_fd
  fun num_bytes(): USize =>
    var sum = USize(0)
    for (_, size) in _iovec.values() do
      sum = sum + size
    end
    sum


primitive _AtFdcwd
  """
  AT_FDCWD - see definition in fcntl.h
  """
  fun apply(): I32 =>
    -100

class iso OpOpenat
  """
  Uses openat to open relative paths in the current working directory.
  Absolute paths are opened as one would expect.
  """
  let _dir_fd: I32
  let _path: FilePath
  let _flags: I32
  let _mode: U32
  let _sqe_flags: SQEFlags

  new iso create(
    path': FilePath,
    dir_fd': I32 = _AtFdcwd(),
    flags': I32 = @ponyint_o_rdwr() or @ponyint_o_creat() or @ponyint_o_trunc(),
    mode': U32 = 0,
    sqe_flags': SQEFlags = SQEFlags
  ) ? =>
    """
    Open file for RW, create it if it does not exist, truncate it if it does.
    Manipulate the `flags'` and `mode'` arguments to get a different open behaviour.
    """
    verify_caps(flags', path')?
    _dir_fd = dir_fd'
    _path = path'
    _flags = flags'
    _mode = mode'
    _sqe_flags = sqe_flags'

  new iso read_only(
    path': FilePath,
    dir_fd': I32 = _AtFdcwd(),
    flags': I32 = @ponyint_o_rdonly(),
    sqe_flags': SQEFlags = SQEFlags
  ) ? =>
    """
    Open file for read only.
    """
    verify_caps(flags', path')?
    _dir_fd = dir_fd'
    _path = path'
    _flags = flags'
    _mode = 0
    _sqe_flags = sqe_flags'

  fun tag verify_caps(flags': I32, path': FilePath) ? =>
    if ((flags' and @ponyint_o_creat()) != 0) and not path'.caps(FileCreate) then
      error
    end

    if ((flags' and @ponyint_o_trunc()) != 0) and not path'.caps(FileTruncate) then
      error
    end

    if ((flags' and @ponyint_o_rdwr()) != 0) and not path'.caps(FileWrite) then
      error
    end

    if ((flags' and @ponyint_o_rdonly()) != 0) and not path'.caps(FileRead) then
      error
    end

  fun kind(): OpKind => OpKindOpenat
  fun sqe_flags(): SQEFlags => _sqe_flags

  fun dir_fd(): I32 => _dir_fd
  fun path(): FilePath => _path
  fun flags(): I32 => _flags
  fun mode(): U32 => _mode


class iso OpClose
  var _fd: I32
  let _sqe_flags: SQEFlags

  new iso create(fd': I32, sqe_flags': SQEFlags = SQEFlags) =>
    _fd = fd'
    _sqe_flags = sqe_flags'

  fun kind(): OpKind => OpKindClose
  fun sqe_flags(): SQEFlags => _sqe_flags

  fun fd(): I32 => _fd
  fun ref set_fd(fd': I32) =>
    _fd = fd'


class iso OpFsync
  var _fd: I32
  let _fdatasync: Bool
  let _sqe_flags: SQEFlags

  new iso create(fd': I32, fdatasync': Bool = false, sqe_flags': SQEFlags = SQEFlags) =>
    _fd = fd'
    _fdatasync = fdatasync'
    _sqe_flags = sqe_flags'

  fun kind(): OpKind => OpKindFsync
  fun sqe_flags(): SQEFlags => _sqe_flags

  fun fd(): I32 => _fd
  fun ref set_fd(fd': I32) =>
    _fd = fd'
  fun fdatasync(): Bool => _fdatasync



type OpKind is (OpKindNop | OpKindReadv | OpKindWritev | OpKindFsync | OpKindReadFixed | OpKindWriteFixed | OpKindPollAdd | OpKindPollRemove | OpKindSyncFileRange | OpKindSendmsg |  OpKindRecvmsg | OpKindTimeout | OpKindTimeoutRemove | OpKindAccept | OpKindAsyncCancel | OpKindLinkTimeout | OpKindConnect | OpKindFallocate | OpKindOpenat | OpKindClose | OpKindFilesUpdate | OpKindStatx | OpKindRead | OpKindWrite | OpKindFadvise | OpKindMadvise | OpKindSend | OpKindRecv | OpKindOpenat2 | OpKindEpollctl | OpKindSplice | OpKindProvideBuffers | OpKindRemoveBuffers | OpKindTee | OpKindShutdown | OpKindRenameat | OpKindUnlinkat | OpKindMkdirat | OpKindSymlinkat | OpKindLinkat)

primitive OpKinds
  fun apply(): Array[OpKind] val^ =>
    """
    Returns an array of all ops listed in liburing-2.1.
    """
    [
      OpKindNop
      OpKindReadv
      OpKindWritev
      OpKindFsync
      OpKindReadFixed
      OpKindWriteFixed
      OpKindPollAdd
      OpKindPollRemove
      OpKindSyncFileRange
      OpKindSendmsg
      OpKindRecvmsg
      OpKindTimeout
      OpKindTimeoutRemove
      OpKindAccept
      OpKindAsyncCancel
      OpKindLinkTimeout
      OpKindConnect
      OpKindFallocate
      OpKindOpenat
      OpKindClose
      OpKindFilesUpdate
      OpKindStatx
      OpKindRead
      OpKindWrite
      OpKindFadvise
      OpKindMadvise
      OpKindSend
      OpKindRecv
      OpKindOpenat2
      OpKindEpollctl
      OpKindSplice
      OpKindProvideBuffers
      OpKindRemoveBuffers
      OpKindTee
      OpKindShutdown
      OpKindRenameat
      OpKindUnlinkat
      OpKindMkdirat
      OpKindSymlinkat
      OpKindLinkat
    ]

primitive OpKindNop
  """
  IORING_OP_NOP
  """
  fun value(): I32 => 0
  fun string(): String => "IORING_OP_NOP"

primitive OpKindReadv
  """
  IORING_OP_READV
  """
  fun value(): I32 => 1
  fun string(): String => "IORING_OP_READV"

primitive OpKindWritev
  """
  IORING_OP_WRITEV
  """
  fun value(): I32 => 2
  fun string(): String => "IORING_OP_WRITEV"

primitive OpKindFsync
  """
  IORING_OP_FSYNC
  """
  fun value(): I32 => 3
  fun string(): String => "IORING_OP_FSYNC"

primitive OpKindReadFixed
  """
  IORING_OP_READ_FIXED
  """
  fun value(): I32 => 4
  fun string(): String => "IORING_OP_READ_FIXED"

primitive OpKindWriteFixed
  """
  IORING_OP_WRITE_FIXED
  """
  fun value(): I32 => 5
  fun string(): String => "IORING_OP_WRITE_FIXED"

primitive OpKindPollAdd
  """
  IORING_OP_POLL_ADD
  """
  fun value(): I32 => 6
  fun string(): String => "IORING_OP_POLL_ADD"

primitive OpKindPollRemove
  """
  IORING_OP_POLL_REMOVE
  """
  fun value(): I32 => 7
  fun string(): String => "IORING_OP_POLL_REMOVE"

primitive OpKindSyncFileRange
  """
  IORING_OP_SYNC_FILE_RANGE
  """
  fun value(): I32 => 8
  fun string(): String => "IORING_OP_SYNC_FILE_RANGE"

primitive OpKindSendmsg
  """
  IORING_OP_SENDMSG
  """
  fun value(): I32 => 9
  fun string(): String => "IORING_OP_SENDMSG"

primitive OpKindRecvmsg
  """
  IORING_OP_RECVMSG
  """
  fun value(): I32 => 10
  fun string(): String => "IORING_OP_RECVMSG"

primitive OpKindTimeout
  """
  IORING_OP_TIMEOUT
  """
  fun value(): I32 => 11
  fun string(): String => "IORING_OP_TIMEOUT"

primitive OpKindTimeoutRemove
  """
  IORING_OP_TIMEOUT_REMOVE
  """
  fun value(): I32 => 12
  fun string(): String => "IORING_OP_TIMEOUT_REMOVE"

primitive OpKindAccept
  """
  IORING_OP_ACCEPT
  """
  fun value(): I32 => 13
  fun string(): String => "IORING_OP_ACCEPT"

primitive OpKindAsyncCancel
  """
  IORING_OP_ASYNC_CANCEL
  """
  fun value(): I32 => 14
  fun string(): String => "IORING_OP_ASYNC_CANCEL"

primitive OpKindLinkTimeout
  """
  IORING_OP_LINK_TIMEOUT
  """
  fun value(): I32 => 15
  fun string(): String => "IORING_OP_LINK_TIMEOUT"

primitive OpKindConnect
  """
  IORING_OP_CONNECT
  """
  fun value(): I32 => 16
  fun string(): String => "IORING_OP_CONNECT"

primitive OpKindFallocate
  """
  IORING_OP_FALLOCATE
  """
  fun value(): I32 => 17
  fun string(): String => "IORING_OP_FALLOCATE"

primitive OpKindOpenat
  """
  IORING_OP_OPENAT
  """
  fun value(): I32 => 18
  fun string(): String => "IORING_OP_OPENAT"

primitive OpKindClose
  """
  IORING_OP_CLOSE
  """
  fun value(): I32 => 19
  fun string(): String => "IORING_OP_CLOSE"

primitive OpKindFilesUpdate
  """
  IORING_OP_FILES_UPDATE
  """
  fun value(): I32 => 20
  fun string(): String => "IORING_OP_FILES_UPDATE"

primitive OpKindStatx
  """
  IORING_OP_STATX
  """
  fun value(): I32 => 21
  fun string(): String => "IORING_OP_STATX"

primitive OpKindRead
  """
  IORING_OP_READ
  """
  fun value(): I32 => 22
  fun string(): String => "IORING_OP_READ"

primitive OpKindWrite
  """
  IORING_OP_WRITE
  """
  fun value(): I32 => 23
  fun string(): String => "IORING_OP_WRITE"

primitive OpKindFadvise
  """
  IORING_OP_FADVISE
  """
  fun value(): I32 => 24
  fun string(): String => "IORING_OP_FADVISE"

primitive OpKindMadvise
  """
  IORING_OP_MADVISE
  """
  fun value(): I32 => 25
  fun string(): String => "IORING_OP_MADVISE"

primitive OpKindSend
  """
  IORING_OP_SEND
  """
  fun value(): I32 => 26
  fun string(): String => "IORING_OP_SEND"

primitive OpKindRecv
  """
  IORING_OP_RECV
  """
  fun value(): I32 => 27
  fun string(): String => "IORING_OP_RECV"

primitive OpKindOpenat2
  """
  IORING_OP_OPENAT2
  """
  fun value(): I32 => 28
  fun string(): String => "IORING_OP_OPENAT2"

primitive OpKindEpollctl
  """
  IORING_OP_EPOLLCTL
  """
  fun value(): I32 => 29
  fun string(): String => "IORING_OP_EPOLLCTL"

primitive OpKindSplice
  """
  IORING_OP_SPLICE
  """
  fun value(): I32 => 30
  fun string(): String => "IORING_OP_SPLICE"

primitive OpKindProvideBuffers
  """
  IORING_OP_PROVIDE_BUFFERS
  """
  fun value(): I32 => 31
  fun string(): String => "IORING_OP_PROVIDE_BUFFERS"

primitive OpKindRemoveBuffers
  """
  IORING_OP_REMOVE_BUFFERS
  """
  fun value(): I32 => 32
  fun string(): String => "IORING_OP_REMOVE_BUFFERS"

primitive OpKindTee
  """
  IORING_OP_TEE
  """
  fun value(): I32 => 33
  fun string(): String => "IORING_OP_TEE"

primitive OpKindShutdown
  """
  IORING_OP_SHUTDOWN
  """
  fun value(): I32 => 34
  fun string(): String => "IORING_OP_SHUTDOWN"

primitive OpKindRenameat
  """
  IORING_OP_RENAMEAT
  """
  fun value(): I32 => 35
  fun string(): String => "IORING_OP_RENAMEAT"

primitive OpKindUnlinkat
  """
  IORING_OP_UNLINKAT
  """
  fun value(): I32 => 36
  fun string(): String => "IORING_OP_UNLINKAT"

primitive OpKindMkdirat
  """
  IORING_OP_MKDIRAT
  """
  fun value(): I32 => 37
  fun string(): String => "IORING_OP_MKDIRAT"

primitive OpKindSymlinkat
  """
  IORING_OP_SYMLINKAT
  """
  fun value(): I32 => 38
  fun string(): String => "IORING_OP_SYMLINKAT"

primitive OpKindLinkat
  """
  IORING_OP_LINKAT
  """
  fun value(): I32 => 39
  fun string(): String => "IORING_OP_LINKAT"

// IORING_OP_LAST left out intentionally

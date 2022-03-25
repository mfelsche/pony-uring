use @pony_uring_sqe_set_data[None](sqe: Pointer[_SQE] ref, data: U64) if linux
use @pony_uring_sqe_set_flags[None](sqe: Pointer[_SQE] ref, flags: U8) if linux
use @pony_uring_prep_nop[None](sqe: Pointer[_SQE] ref) if linux
use @pony_uring_prep_read[None](sqe: Pointer[_SQE] ref, fd: I32, buf: Pointer[U8] tag, nbytes: U32, offset: U64) if linux
use @pony_uring_prep_readv[None](sqe: Pointer[_SQE] ref, fd: I32, iovec: Pointer[(Pointer[U8] tag, USize)] tag, nr_vec: U32, offset: U64) if linux
use @pony_uring_prep_openat[None](sqe: Pointer[_SQE] ref, fd: I32, path: Pointer[U8] tag, flags: I32, mode: U32)
use @pony_uring_prep_close[None](sqe: Pointer[_SQE] ref, fd: I32)
use @pony_uring_prep_fsync[None](sqe: Pointer[_SQE] ref, fd: I32, flags: U32)


use "collections"

type SQEFlag is (SQEFixedFile | SQEDrain | SQELink | SQEHardLink | SQEAlwaysAsync | SQEBufferSelect)
type SQEFlags is Flags[SQEFlag, U8]

primitive SQEFixedFile
  """
  ### IOSQE_FIXED_FILE

  When this flag is specified,
  fd is an index into the files array registered with the io_uring instance
  (see the IORING_REGISTER_FILES section of the io_uring_register(2) man page).

  Available since 5.1.

  Taken from: https://unixism.net/loti/ref-liburing/low_level.html
  """

  fun value(): U8 => 1 << 0

primitive SQEDrain
  """
  ### IOSQE_IO_DRAIN

  When this flag is specified,
  the SQE will not be started before previously submitted SQEs have completed,
  and new SQEs will not be started before this one completes.

  Available since 5.2.

  Taken from: https://unixism.net/loti/ref-liburing/low_level.html
  """
  fun value(): U8 => 1 << 1

primitive SQELink
  """
  ### IOSQE_IO_LINK

  When this flag is specified, it forms a link with the next SQE in the submission ring.
  That next SQE will not be started before this one completes.
  This, in effect, forms a chain of SQEs, which can be arbitrarily long.
  The tail of the chain is denoted by the first SQE that does not have this flag set.
  This flag has no effect on previous SQE submissions,
  nor does it impact SQEs that are outside of the chain tail.
  This means that multiple chains can be executing in parallel,
  or chains and individual SQEs.
  Only members inside the chain are serialized.
  A chain of SQEs will be broken, if any request in that chain ends in error.
  io_uring considers any unexpected result an error.
  This means that, eg, a short read will also terminate the remainder of the chain.
  If a chain of SQE links is broken,
  the remaining unstarted part of the chain will be terminated
  and completed with -ECANCELED as the error code.

  Available since 5.3.

  Taken from: https://unixism.net/loti/ref-liburing/low_level.html
  """
  fun value(): U8 => 1 << 2

primitive SQEHardLink
  """
  ### IOSQE_IO_HARDLINK

  Like IOSQE_IO_LINK, but it doesn’t sever regardless of the completion result.
  Note that the link will still sever if we fail submitting the parent request,
  hard links are only resilient in the presence of completion results
  for requests that did submit correctly.

  IOSQE_IO_HARDLINK implies IOSQE_IO_LINK.

  Available since 5.5.

  Taken from: https://unixism.net/loti/ref-liburing/low_level.html
  """
  fun value(): U8 => 1 << 3

primitive SQEAlwaysAsync
  """
  ### IOSQE_ASYNC

  Normal operation for io_uring is to try and issue an sqe as non-blocking first,
  and if that fails, execute it in an async manner.
  To support more efficient overlapped operation of requests
  that the application knows/assumes will always (or most of the time) block,
  the application can ask for an sqe to be issued async from the start.

  Available since 5.6.

  Taken from: https://unixism.net/loti/ref-liburing/low_level.html
  """
  fun value(): U8 => 1 << 4

primitive SQEBufferSelect
  """
  ### IOSQE_BUFFER_SELECT

  select buffer from sqe->buf_group
  """
  fun value(): U8 => 1 << 5


primitive _SQE
  """SQE dummy primitive"""

class ref SQEBuilder
  """
  exposed methods to fill a SQE
  """
  var _inner: Pointer[_SQE]
  var _flags: SQEFlags

  new ref _create(inner: Pointer[_SQE] ref) =>
    _inner = inner
    _flags = SQEFlags

  fun ref set_data(data: U64) =>
    """
    data is just an opaque token,
    only for referencing a pending operation inside our ring
    """
    ifdef linux then
      @pony_uring_sqe_set_data(_inner, data)
    else
      compile_error "uring only supported on linux"
    end

  fun ref drain() =>
    """
    Only execute this SQE after all previous once are done,
    and only start the next SQE after this one, when this SEQ's operation is completed.

    See [SQEDrain](uring-SQEDrain.md)
    """
    _flags.set(SQEDrain)

  fun ref always_async() =>
    """
    Don't try to run this SQE as non-blocking first, simply run it as async.

    Useful if this op is known to block (e.g. file reads/writes).

    See [SQEAlwaysAsync](uring-SQEAlwaysAsync.md)
    """
    _flags.set(SQEAlwaysAsync)

  fun ref link() =>
    """
    Link this SQE entry to the following one.

    See [SQELink](uring-SQELink.md) for more information on the semantics of linking.
    """
    _flags.set(SQELink)

  fun ref hard_link() =>
    """
    Hard-link this SQE entry to the following one.

    See [SQEHardLink](uring-SQEHardLink.md) for more information
    on the semantics of hard linking.

    This implies [SQELink](uring-SQELink.md).
    """
    _flags.set(SQELink)

  fun ref set_flags(flags: SQEFlags) =>
    """
    Set flags for this SQE.
    """
    _flags = flags

  fun ref clear_flags() =>
    _flags.clear()

  fun ref nop(op: OpNop iso): OpNop iso^ =>
    ifdef linux then
      @pony_uring_prep_nop(_inner)
      @pony_uring_sqe_set_flags(_inner, _flags.value())
      consume op
    else
      compile_error "uring only supported on linux"
    end

  fun ref read(op: OpRead iso): OpRead iso^ =>
    ifdef linux then
      @pony_uring_prep_read(_inner, op.fd(), op.buf(), op.nbytes(), op.offset())
      @pony_uring_sqe_set_flags(_inner, _flags.value())
      consume op
    else
      compile_error "uring only supported on linux"
    end

  fun ref readv(op: OpReadv iso): OpReadv iso^ =>
    ifdef linux then
      @pony_uring_prep_readv(_inner, op.fd(), op.iovec(), op.numvecs(), op.offset())
      @pony_uring_sqe_set_flags(_inner, _flags.value())
      consume op
    else
      compile_error "uring only supported on linux"
    end

  fun ref fsync(op: OpFsync iso): OpFsync iso^ =>
    ifdef linux then
      let flags: U32 = if op.fdatasync() then 1 else 0 end
      @pony_uring_prep_fsync(_inner, op.fd(), flags)
      @pony_uring_sqe_set_flags(_inner, _flags.value())
      consume op
    else
      compile_error "uring only supported on linux"
    end

  fun ref openat(op: OpOpenat iso): OpOpenat iso^ =>
    ifdef linux then
      @pony_uring_prep_openat(_inner, op.dir_fd(), op.path().path.cstring(), op.flags(), op.mode())
      @pony_uring_sqe_set_flags(_inner, _flags.value())
      consume op
    else
      compile_error "uring only supported on linux"
    end


  fun ref close(op: OpClose iso): OpClose iso^ =>
    ifdef linux then
      @pony_uring_prep_close(_inner, op.fd())
      @pony_uring_sqe_set_flags(_inner, _flags.value())
      consume op
    else
      compile_error "uring only supported on linux"
    end

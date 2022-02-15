use "path:.." if linux
use "lib:uring" if linux
use "lib:uring_pony" if linux
use "collections"

use @io_uring_queue_init[I32](entries: U32, ring: NullablePointer[_Ring] box, flags: U32) if linux
use @io_uring_queue_exit[None](ring: NullablePointer[_Ring] box) if linux
use @io_uring_ring_dontfork[I32](ring: NullablePointer[_Ring] box) if linux

use @io_uring_get_sqe[Pointer[_SQE]](ring: NullablePointer[_Ring] box) if linux
use @io_uring_submit[I32](ring: NullablePointer[_Ring] box) if linux

struct _SubmissionQueue
  let khead: Pointer[U32] = khead.create()
  let ktail: Pointer[U32] = ktail.create()
  let kring_mask: Pointer[U32] = kring_mask.create()
  let kring_entries: Pointer[U32] = kring_entries.create()
  let kflags: Pointer[U32] = kflags.create()
  let kdropped: Pointer[U32] = kdropped.create()
  let array: Pointer[U32] = array.create()
  let sqes: Pointer[_SQE] = sqes.create()

  let sqe_head: U32 = 0
  let sqe_tail: U32 = 0

  let ring_sz: USize = 0
  let ring_ptr: Pointer[None] = ring_ptr.create()

  let _pad1: U32 = 0
  let _pad2: U32 = 0
  let _pad3: U32 = 0
  let _pad4: U32 = 0

primitive _CQE
  """Dummy placeholder"""

struct _CompletionQueue
  let khead: Pointer[U32] = khead.create()
  let ktail: Pointer[U32] = ktail.create()
  let kring_mask: Pointer[U32] = kring_mask.create()
  let kring_entries: Pointer[U32] = kring_entries.create()
  let kflags: Pointer[U32] = kflags.create()
  let koverflow: Pointer[U32] = koverflow.create()
  let cqes: Pointer[_CQE] = cqes.create()

  let ring_sz: USize = 0
  let ring_ptx: Pointer[None] = ring_ptx.create()

  let _pad1: U32 = 0
  let _pad2: U32 = 0
  let _pad3: U32 = 0
  let _pad4: U32 = 0

struct _Ring
  embed sq: _SubmissionQueue = _SubmissionQueue.create()
  embed cq: _CompletionQueue = _CompletionQueue.create()

  let flags: U32 = 0
  let ring_fd: I32 = 0

  let features: U32 = 0
  let _pad1: U32 = 0
  let _pad2: U32 = 0
  let _pad3: U32 = 0

  new create() => None

primitive InitURing
  """
  Public initializer for the URing actor
  """
  fun apply(entries: U32, flags: SetupFlags = SetupFlags.create()): URing ? =>
    ifdef linux then
      let ring = recover val NullablePointer[_Ring](_Ring.create()) end
      if @io_uring_queue_init(entries, ring, flags.value()) == 0 then
        URing._create(ring)
      else
        error
      end
    else
      compile_error "uring only supported on linux"
    end


actor URing
  """
  Actor representing an io_uring instance.

  Create a `URing` actor by calling the `InitURing.apply()` method as in the following example:

  ```pony
  use "uring"
  actor Main
    new create(env: Env) =>
      try
        let uring = InitUring(where entries = 128, flags = SetupFlags.add(SetupSqPoll))?
      else
        env.err.print("Error setting up URing")
      end
  ```
  """
  let _ring: NullablePointer[_Ring] val

  new _create(ring: NullablePointer[_Ring] val) =>
    """
    Expects a pointer to a _Ring struct that has already been initialized
    """
    _ring = consume ring

  fun get_sqe(): SQEBuilder ? =>
    """
    TODO: rework how this is done
    """
    ifdef linux then
      let sqe = @io_uring_get_sqe(_ring)
      if sqe.is_null() then
        error
      else
        SQEBuilder._create(sqe)
      end
    else
      compile_error "uring only supported on linux"
    end

  fun submit(): USize =>
    ifdef linux then
      @io_uring_submit(_ring).usize()
    else
      compile_error "uring only supported on linux"
    end

  be dispose() =>
    close()

  fun ref close() =>
    ifdef linux then
      @io_uring_queue_exit(_ring)
    else
      compile_error "uring only supported on linux"
    end

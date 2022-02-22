use "path:.." if linux
use "lib:uring" if linux
use "lib:uring_pony" if linux
use "collections"
use "./event_fd"
use "debug"

use @pony_asio_event_create[AsioEventID](owner: AsioEventNotify, fd: U32,
  flags: U32, nsec: U64, noisy: Bool)
use @pony_asio_event_unsubscribe[None](event: AsioEventID)
use @pony_asio_event_destroy[None](event: AsioEventID)
use @pony_asio_event_fd[U32](event: AsioEventID)
use @pony_asio_event_resubscribe_read[None](event: AsioEventID)
use @pony_asio_event_resubscribe_write[None](event: AsioEventID)
use @pony_asio_event_get_disposable[Bool](event: AsioEventID)
use @pony_asio_event_set_writeable[None](event: AsioEventID, writeable: Bool)
use @pony_asio_event_set_readable[None](event: AsioEventID, readable: Bool)

use @io_uring_queue_init[I32](entries: U32, ring: NullablePointer[_Ring] box, flags: U32) if linux
use @io_uring_queue_exit[None](ring: NullablePointer[_Ring] box) if linux
use @io_uring_ring_dontfork[I32](ring: NullablePointer[_Ring] box) if linux

use @pony_uring_cq_ready[U64](ring: NullablePointer[_Ring] box) if linux
use @pony_uring_cqe_seen[None](ring: NullablePointer[_Ring] box, cqe: NullablePointer[CQE]) if linux
use @pony_uring_peek_cqe[NullablePointer[CQE]](ring: NullablePointer[_Ring] box) if linux

use @io_uring_register_eventfd[I32](ring: NullablePointer[_Ring] box, fd: I32) if linux
use @io_uring_unregister_eventfd[I32](ring: NullablePointer[_Ring] box) if linux

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

struct _CompletionQueue
  let khead: Pointer[U32] = khead.create()
  let ktail: Pointer[U32] = ktail.create()
  let kring_mask: Pointer[U32] = kring_mask.create()
  let kring_entries: Pointer[U32] = kring_entries.create()
  let kflags: Pointer[U32] = kflags.create()
  let koverflow: Pointer[U32] = koverflow.create()
  let cqes: Pointer[CQE] = cqes.create()

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
  Public initializer for the URing actor.

  Example usage:

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
  fun apply(entries: U32, flags: SetupFlags = SetupFlags.create()): URing ? =>
    ifdef linux then
      let ring = recover val NullablePointer[_Ring](_Ring.create()) end
      if @io_uring_queue_init(entries, ring, flags.value()) == 0 then
        let event_fd = recover iso EventFd.create()? end
        URing._create(ring, consume event_fd)
      else
        error
      end
    else
      compile_error "uring only supported on linux"
    end


actor URing is AsioEventNotify
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
  let _asio_event: AsioEventID
  let _ring: NullablePointer[_Ring] val
  let _event_fd: EventFd iso
  let _pending_ops: MapIs[U64, (URingOp iso, URingNotify tag)] = _pending_ops.create()
    """
    We do keep track of the actual operation struct embedding data needed at completion time
    and of the actual notify actor.
    """

  var _op_count: U64 = 0
    """
    Keeping track of the number of ops
    in order to assign a unique token to each
    """


  new _create(ring: NullablePointer[_Ring] val, event_fd: EventFd iso) =>
    """
    Expects a pointer to a _Ring struct that has already been initialized
    and a successfully initialized eventfd
    """
    _ring = ring
    _event_fd = consume event_fd
    ifdef linux then
      // we will only ever get here on linux
      @io_uring_register_eventfd(_ring, _event_fd.file_descriptor())
    end
    _asio_event = @pony_asio_event_create(this, _event_fd.file_descriptor().u32(), AsioEvent.read(), 0, true)

  be _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    if AsioEvent.readable(flags) then
      ifdef linux then
        var cqe_ptr = @pony_uring_peek_cqe(_ring)
        while not cqe_ptr.is_none() do
          try
            let cqe: CQE = cqe_ptr()?
            let res = cqe.res
            let op_token = cqe.user_data
            @pony_uring_cqe_seen(_ring, NullablePointer[CQE](cqe))
            try
              (_, (let op, let notify)) = _pending_ops.remove(op_token)?
              notify.op_completed(consume op, res)
            else
              Debug("No pending op available for token " + op_token.string())
            end
          end
          cqe_ptr = @pony_uring_peek_cqe(_ring)
        end
      else
        compile_error "uring only supported on linux"
      end
    elseif AsioEvent.disposable(flags) then
      @pony_asio_event_destroy(_asio_event)
    end

  fun ref get_sqe(): SQEBuilder ref ? =>
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

  be submit(op: URingOp iso, notify: URingNotify tag) =>
    match consume op
    | let nop: OpNop =>
      // TODO: what to do when there is no sqe?
      // enqueue the operation into a buffer
      let sqe = try get_sqe()? end
      match sqe
      | let sqee: SQEBuilder ref =>

        let op_token: U64 = _op_count = _op_count + 1
        _pending_ops.insert(op_token, (consume nop, notify))
        sqee.>set_data(op_token).>nop()
      else
        notify.failed(consume nop)
        return // make sure we dont submit as there is no need to
      end
    end
    // TODO: only submit if we aren't in SQPoll Mode
    _submit()

  fun _submit(): USize =>
    ifdef linux then
      @io_uring_submit(_ring).usize()
    else
      compile_error "uring only supported on linux"
    end

  be dispose() =>
    close()

  fun ref close() =>
    ifdef linux then
      @pony_asio_event_unsubscribe(_asio_event)
      @pony_asio_event_set_readable(_asio_event, false)
      @io_uring_unregister_eventfd(_ring)
      _event_fd.close()
      @io_uring_queue_exit(_ring)
    else
      compile_error "uring only supported on linux"
    end

interface URingNotify
  be op_completed(op: URingOp, result: I32)
  be failed(op: URingOp)
    """E.g. when we couldn't get an SQE for this OP"""


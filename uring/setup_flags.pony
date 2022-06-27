use "collections"

primitive SetupIoPoll
  """
  IORING_SETUP_IOPOLL

  Perform busy-waiting for an I/O completion, as opposed to getting notifications via an asynchronous IRQ (Interrupt Request). The file system (if any) and block device must support polling in order for this to work. Busy-waiting provides lower latency, but may consume more CPU resources than interrupt driven I/O. Currently, this feature is usable only on a file descriptor opened using the O_DIRECT flag. When a read or write is submitted to a polled context, the application must poll for completions on the CQ ring by calling io_uring_enter(2). It is illegal to mix and match polled and non-polled I/O on an io_uring instance.

  https://unixism.net/loti/ref-iouring/io_uring_setup.html#io-uring-setup
  """
  fun value(): U32 => 1 << 0

primitive SetupSqPoll
  """
  IORING_SETUP_SQPOLL

  When this flag is specified, a kernel thread is created to perform submission queue polling. An io_uring instance configured in this way enables an application to issue I/O without ever context switching into the kernel.

  https://unixism.net/loti/ref-iouring/io_uring_setup.html#io-uring-setup
  """
  fun value(): U32 => 1 << 1

primitive SetupSqAff
  """
  IORING_SETUP_SQ_AFF

  If this flag is specified, then the poll thread will be bound to the cpu set in the sq_thread_cpu field of the struct io_uring_params. This flag is only meaningful when IORING_SETUP_SQPOLL is specified.

  https://unixism.net/loti/ref-iouring/io_uring_setup.html#io-uring-setup
  """
  fun value(): U32 => 1 << 2

primitive SetupCqSize
  """
  IORING_SETUP_CQSIZE

  App defines completion queue size.

  Create the completion queue with struct io_uring_params.cq_entries entries.

  https://unixism.net/loti/ref-iouring/io_uring_setup.html#io-uring-setup
  """
  fun value(): U32 => 1 << 3

primitive SetupClamp
  """
  IORING_SETUP_CLAMP

  clamp submission / completion queue ring sizes
  """
  fun value(): U32 => 1 << 4

primitive SetupAttachWq
  """
  IORING_SETUP_ATTACH_WQ

  Attach to existing WQ.
  """
  fun value(): U32 => 1 << 5

primitive SetupRDisabled
  """
  IORING_SETUP_R_DISABLED

  Start with ring disabled.
  """
  fun value(): U32 => 1 << 6

primitive SetupSubmitAll
  """
  IORING_SETUP_SUBMIT_ALL

  Continue submit on error.
  """
  fun value(): U32 => 1 << 7

primitive SetupCoopTaskRun
  """
  IORING_SETUP_COOP_TASKRUN

  Cooperative task running.
  """
  fun value(): U32 => 1 << 8

primitive SetupTaskRunFlag
  """
  IORING_SETUP_TASKRUN_FLAG

  sets IORING_SQ_TASKRUN in the sq ring to signal a kernel transition is necessary
  """
  fun value(): U32 => 1 << 9

primitive SetupSQE128
  """
  IORING_SETUP_SQE128

  SQEs are 128 Bytes
  """
  fun value(): U32 => 1 << 10

primitive SetupCQE32
  """
  IORING_SETUP_CQE32

  CQEs are 32 byte
  """
  fun value(): U32 => 1 << 11

type SetupFlags is Flags[(SetupIoPoll|SetupSqPoll|SetupSqAff|SetupCqSize|SetupClamp|SetupAttachWq|SetupRDisabled|SetupSubmitAll|SetupCoopTaskRun|SetupTaskRunFlag|SetupSQE128|SetupCQE32), U32]
  """
  io_uring_setup() flags to be passed to `Ring.create()`.
  """

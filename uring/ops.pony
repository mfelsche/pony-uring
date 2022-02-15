type Op is (OpNop | OpReadv | OpWritev | OpFsync | OpReadFixed | OpWriteFixed | OpPollAdd | OpPollRemove | OpSyncFileRange | OpSendmsg |  OpRecvmsg | OpTimeout | OpTimeoutRemove | OpAccept | OpAsyncCancel | OpLinkTimeout | OpConnect | OpFallocate | OpOpenat | OpClose | OpFilesUpdate | OpStatx | OpRead | OpWrite | OpFadvise | OpMadvise | OpSend | OpRecv | OpOpenat2 | OpEpollctl | OpSplice | OpProvideBuffers | OpRemoveBuffers | OpTee | OpShutdown | OpRenameat | OpUnlinkat | OpMkdirat | OpSymlinkat | OpLinkat)

primitive Ops
  fun apply(): Array[Op] val^ =>
    """
    Returns an array of all ops listed in liburing-2.1.
    """
    [
      OpNop
      OpReadv
      OpWritev
      OpFsync
      OpReadFixed
      OpWriteFixed
      OpPollAdd
      OpPollRemove
      OpSyncFileRange
      OpSendmsg
      OpRecvmsg
      OpTimeout
      OpTimeoutRemove
      OpAccept
      OpAsyncCancel
      OpLinkTimeout
      OpConnect
      OpFallocate
      OpOpenat
      OpClose
      OpFilesUpdate
      OpStatx
      OpRead
      OpWrite
      OpFadvise
      OpMadvise
      OpSend
      OpRecv
      OpOpenat2
      OpEpollctl
      OpSplice
      OpProvideBuffers
      OpRemoveBuffers
      OpTee
      OpShutdown
      OpRenameat
      OpUnlinkat
      OpMkdirat
      OpSymlinkat
      OpLinkat
    ]

primitive OpNop
  """
  IORING_OP_NOP
  """
  fun value(): I32 => 0
  fun string(): String => "IORING_OP_NOP"

primitive OpReadv
  """
  IORING_OP_READV
  """
  fun value(): I32 => 1
  fun string(): String => "IORING_OP_READV"

primitive OpWritev
  """
  IORING_OP_WRITEV
  """
  fun value(): I32 => 2
  fun string(): String => "IORING_OP_WRITEV"

primitive OpFsync
  """
  IORING_OP_FSYNC
  """
  fun value(): I32 => 3
  fun string(): String => "IORING_OP_FSYNC"

primitive OpReadFixed
  """
  IORING_OP_READ_FIXED
  """
  fun value(): I32 => 4
  fun string(): String => "IORING_OP_READ_FIXED"

primitive OpWriteFixed
  """
  IORING_OP_WRITE_FIXED
  """
  fun value(): I32 => 5
  fun string(): String => "IORING_OP_WRITE_FIXED"

primitive OpPollAdd
  """
  IORING_OP_POLL_ADD
  """
  fun value(): I32 => 6
  fun string(): String => "IORING_OP_POLL_ADD"

primitive OpPollRemove
  """
  IORING_OP_POLL_REMOVE
  """
  fun value(): I32 => 7
  fun string(): String => "IORING_OP_POLL_REMOVE"

primitive OpSyncFileRange
  """
  IORING_OP_SYNC_FILE_RANGE
  """
  fun value(): I32 => 8
  fun string(): String => "IORING_OP_SYNC_FILE_RANGE"

primitive OpSendmsg
  """
  IORING_OP_SENDMSG
  """
  fun value(): I32 => 9
  fun string(): String => "IORING_OP_SENDMSG"

primitive OpRecvmsg
  """
  IORING_OP_RECVMSG
  """
  fun value(): I32 => 10
  fun string(): String => "IORING_OP_RECVMSG"

primitive OpTimeout
  """
  IORING_OP_TIMEOUT
  """
  fun value(): I32 => 11
  fun string(): String => "IORING_OP_TIMEOUT"

primitive OpTimeoutRemove
  """
  IORING_OP_TIMEOUT_REMOVE
  """
  fun value(): I32 => 12
  fun string(): String => "IORING_OP_TIMEOUT_REMOVE"

primitive OpAccept
  """
  IORING_OP_ACCEPT
  """
  fun value(): I32 => 13
  fun string(): String => "IORING_OP_ACCEPT"

primitive OpAsyncCancel
  """
  IORING_OP_ASYNC_CANCEL
  """
  fun value(): I32 => 14
  fun string(): String => "IORING_OP_ASYNC_CANCEL"

primitive OpLinkTimeout
  """
  IORING_OP_LINK_TIMEOUT
  """
  fun value(): I32 => 15
  fun string(): String => "IORING_OP_LINK_TIMEOUT"

primitive OpConnect
  """
  IORING_OP_CONNECT
  """
  fun value(): I32 => 16
  fun string(): String => "IORING_OP_CONNECT"

primitive OpFallocate
  """
  IORING_OP_FALLOCATE
  """
  fun value(): I32 => 17
  fun string(): String => "IORING_OP_FALLOCATE"

primitive OpOpenat
  """
  IORING_OP_OPENAT
  """
  fun value(): I32 => 18
  fun string(): String => "IORING_OP_OPENAT"

primitive OpClose
  """
  IORING_OP_CLOSE
  """
  fun value(): I32 => 19
  fun string(): String => "IORING_OP_CLOSE"

primitive OpFilesUpdate
  """
  IORING_OP_FILES_UPDATE
  """
  fun value(): I32 => 20
  fun string(): String => "IORING_OP_FILES_UPDATE"

primitive OpStatx
  """
  IORING_OP_STATX
  """
  fun value(): I32 => 21
  fun string(): String => "IORING_OP_STATX"

primitive OpRead
  """
  IORING_OP_READ
  """
  fun value(): I32 => 22
  fun string(): String => "IORING_OP_READ"

primitive OpWrite
  """
  IORING_OP_WRITE
  """
  fun value(): I32 => 23
  fun string(): String => "IORING_OP_WRITE"

primitive OpFadvise
  """
  IORING_OP_FADVISE
  """
  fun value(): I32 => 24
  fun string(): String => "IORING_OP_FADVISE"

primitive OpMadvise
  """
  IORING_OP_MADVISE
  """
  fun value(): I32 => 25
  fun string(): String => "IORING_OP_MADVISE"

primitive OpSend
  """
  IORING_OP_SEND
  """
  fun value(): I32 => 26
  fun string(): String => "IORING_OP_SEND"

primitive OpRecv
  """
  IORING_OP_RECV
  """
  fun value(): I32 => 27
  fun string(): String => "IORING_OP_RECV"

primitive OpOpenat2
  """
  IORING_OP_OPENAT2
  """
  fun value(): I32 => 28
  fun string(): String => "IORING_OP_OPENAT2"

primitive OpEpollctl
  """
  IORING_OP_EPOLLCTL
  """
  fun value(): I32 => 29
  fun string(): String => "IORING_OP_EPOLLCTL"

primitive OpSplice
  """
  IORING_OP_SPLICE
  """
  fun value(): I32 => 30
  fun string(): String => "IORING_OP_SPLICE"

primitive OpProvideBuffers
  """
  IORING_OP_PROVIDE_BUFFERS
  """
  fun value(): I32 => 31
  fun string(): String => "IORING_OP_PROVIDE_BUFFERS"

primitive OpRemoveBuffers
  """
  IORING_OP_REMOVE_BUFFERS
  """
  fun value(): I32 => 32
  fun string(): String => "IORING_OP_REMOVE_BUFFERS"

primitive OpTee
  """
  IORING_OP_TEE
  """
  fun value(): I32 => 33
  fun string(): String => "IORING_OP_TEE"

primitive OpShutdown
  """
  IORING_OP_SHUTDOWN
  """
  fun value(): I32 => 34
  fun string(): String => "IORING_OP_SHUTDOWN"

primitive OpRenameat
  """
  IORING_OP_RENAMEAT
  """
  fun value(): I32 => 35
  fun string(): String => "IORING_OP_RENAMEAT"

primitive OpUnlinkat
  """
  IORING_OP_UNLINKAT
  """
  fun value(): I32 => 36
  fun string(): String => "IORING_OP_UNLINKAT"

primitive OpMkdirat
  """
  IORING_OP_MKDIRAT
  """
  fun value(): I32 => 37
  fun string(): String => "IORING_OP_MKDIRAT"

primitive OpSymlinkat
  """
  IORING_OP_SYMLINKAT
  """
  fun value(): I32 => 38
  fun string(): String => "IORING_OP_SYMLINKAT"

primitive OpLinkat
  """
  IORING_OP_LINKAT
  """
  fun value(): I32 => 39
  fun string(): String => "IORING_OP_LINKAT"

// IORING_OP_LAST left out intentionally

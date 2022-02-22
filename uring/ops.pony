type URingOp is (OpNop)

class iso OpNop
  new iso create() => None

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

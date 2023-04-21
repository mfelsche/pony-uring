struct CQE
  """
  Completion Queue Entry.

  Contains the result code of the operation,
  a pointer to user-data supplied with the SQE (Submission Queue Entry)
  and some flags.
  """
  let user_data: U64 = 0
    """
    A pointer. sqe->data submission passed back.
    """
  let res: I32 = 0
    """
    Result code for this event
    """
  let flags: U32 = 0

  // __u64 big_cqe[] - 16 bytes of padding intentionally left out


"""
Simple Wrapper around eventfd on linux
"""

use @eventfd[I32](initval: U64, flags: I32) if linux
use @close[I32](fd: I32) if linux
use "collections"

primitive CloExec
  """
  EFD_CLOEXEC
  """
  fun value(): U32 => 0x80000

primitive Semaphore
  """
  EFD_SEMAPHORE
  """
  fun value(): U32 => 0x1

primitive NonBlock
  """
  EFD_NONBLOCK
  """
  fun value(): U32 => 0x800

type EventFdFlags is Flags[(CloExec | Semaphore | NonBlock), U32]

class EventFd
  var _fd: I32

  new ref create(initial: U64 = 0, flags: EventFdFlags = EventFdFlags.create()) ? =>
    ifdef linux then
      let fd = @eventfd(initial, flags.value().i32())
      if fd == -1 then
        error
      else
        _fd = fd
      end
    else
      compile_error "eventfd only supported on linux"
    end

  fun file_descriptor(): I32 => _fd

  fun ref close() =>
    ifdef linux then
      @close(_fd = -1)
    else
      compile_error "eventfd only supported on linux"
    end

use @pony_uring_sqe_set_data[None](sqe: Pointer[_SQE] ref, data: Any) if linux

primitive _SQE
  """SQE dummy primitive"""

class ref SQEBuilder
  """
  exposed methods to fill a SQE
  """
  let _inner: Pointer[_SQE]

  new ref _create(inner: Pointer[_SQE]) =>
    _inner = inner

  fun ref set_data[T: Any](data: T) =>
    ifdef linux then
      @pony_uring_sqe_set_data(_inner, data)
    else
      compile_error "uring only supported on linux"
    end

//  fun ref nop()


// TODO: do the set_data internally without exposing it to the user
// TODO: at first support nop, read, write


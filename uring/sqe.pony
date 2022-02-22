use @pony_uring_sqe_set_data[None](sqe: Pointer[_SQE] ref, data: U64) if linux
use @pony_uring_prep_nop[None](sqe: Pointer[_SQE] ref) if linux


primitive _SQE
  """SQE dummy primitive"""

class ref SQEBuilder
  """
  exposed methods to fill a SQE
  """
  var _inner: Pointer[_SQE]

  new ref _create(inner: Pointer[_SQE] ref) =>
    _inner = inner

  fun ref set_data(data: U64) =>
    """
    data is just an opaque token, only for referencing apending operation inside our ring
    """
    ifdef linux then
      @pony_uring_sqe_set_data(_inner, data)
    else
      compile_error "uring only supported on linux"
    end

  fun ref nop() =>
    ifdef linux then
      @pony_uring_prep_nop(_inner)
    else
      compile_error "uring only supported on linux"
    end


// TODO: do the set_data internally without exposing it to the user
// TODO: at first support nop, read, write


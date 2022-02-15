use @io_uring_get_probe[Pointer[_Probe] tag]() if linux
use @io_uring_free_probe[None](probe: Pointer[_Probe] tag) if linux
use @pony_uring_opcode_supported[I32](probe: Pointer[_Probe] tag, op: I32) if linux

use "debug"

primitive _Probe

class UringProbe
  let _probe: Pointer[_Probe] tag

  new create() ? =>
    ifdef linux then
      let probe = @io_uring_get_probe()
      if probe.is_null() then
        error
      else
        _probe = probe
      end
    else
      compile_error "uring only supported on linux"
    end

  fun op_supported(op: Op): Bool =>
    ifdef linux then
      @pony_uring_opcode_supported(_probe, op.value()) != 0
    else
      compile_error "uring only supported on linux"
    end

  fun _final() =>
    ifdef linux then
      @io_uring_free_probe(_probe)
    else
      compile_error "uring only supported on linux"
    end

use uring = "uring"
use "format"
use "files"

actor Main
  new create(env: Env) =>
    ifdef linux then
      try
        let ring = uring.InitURing(128)?
        try
          let probe = uring.UringProbe.create()?
          let f = FilePath(env.root, "/proc/sys/kernel/osrelease")
          match OpenFile(f)
          | let file: File =>
            let kernel_release = file.lines().next()?
            env.out.print("io_uring on Kernel " + consume kernel_release)
          else
            env.err.print("Unable to detect kernel version")
          end
          let header = Format("OPCODE" where width = 30, align = AlignLeft)
          header.append("SUPPORTED")
          env.out.print(consume header)
          env.out.print(Format("=" where width = 39, fill = '='))

          for op in uring.Ops().values() do
            let s = Format(op.string() where width = 30, align = AlignLeft)
            if probe.op_supported(op) then
              s.append("\u2705")
            else
              s.append("\u274C")
            end
            env.out.print(consume s)
          end
        else
          env.err.print("probe setup failed")
        end
        ring.dispose()
      else
        env.err.print("io_uring setup failed.")
      end
    else
      env.err.print("Not a linux system")
    end

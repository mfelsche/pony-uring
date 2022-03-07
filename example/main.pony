use uring = "uring"
use "format"
use "files"
use "debug"

actor Main is uring.URingNotify

  var _ring: (uring.URing | None) = None

  new create(env: Env) =>
    ifdef linux then
      try
        let ring = uring.InitURing(128)?
        try
          let probe = uring.UringProbe.create()?
          let f = FilePath(FileAuth(env.root), "/proc/sys/kernel/osrelease")
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

          for op in uring.OpKinds().values() do
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
        // FIXME: provide a richer CLI definition for a `cat` subcommand
        if env.args.size() > 1 then
          let file_path: String = env.args(env.args.size() - 1)?
          let config = uring.FileReaderConfig.create(
            FilePath.create(FileAuth(env.root), file_path, FileCaps .> set(FileRead))
            where chunk_size' = 100,
                  nr_chunks'  = 2
          )
          let reader = uring.FileReader.create(
            config,
            ring,
            FilePrintNotify.create(env.out, ring)
          )
        else
          let nop = uring.OpNop.create()
          let that: uring.URingNotify tag = this
          _ring = ring
          ring.submit(consume nop, that)
        end
      else
        env.err.print("io_uring setup failed.")
      end
    else
      env.err.print("Not a linux system")
    end

  be op_completed(op: uring.URingOp, res: I32) =>
    match op
    | let nop: uring.OpNop =>
      Debug("Nop completed with " + res.string())
      match _ring
      | let ring: uring.URing =>
        ring.dispose()
      end
    end

  be failed(op: uring.URingOp) =>
    match op
    | let nop: uring.OpNop =>
      Debug("Nop failed.")
      match _ring
      | let ring: uring.URing =>
        ring.dispose()
      end
    end

class iso FilePrintNotify is uring.FileReaderNotify
  let _out: OutStream
  let _ring: uring.URing

  new iso create(out: OutStream, ring: uring.URing) =>
    _out = out
    _ring = ring

  fun ref on_data(data: Array[U8] iso, offset: U64): uring.ControlFlow =>
    let s = recover val String.from_iso_array(consume data) end
    _out.write(s)
    uring.Continue

  fun ref on_eof() =>
    _out.print("")

  fun ref on_err(errno: I32) =>
    _out.print("ERROR: " + errno.string())
    _ring.dispose()

  fun ref on_close() =>
    _ring.dispose()


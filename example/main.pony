use uring = "uring"
use "format"
use "files"
use "debug"
use "cli"

actor Main is uring.URingNotify

  var _ring: (uring.URing | None) = None
  let _env: Env

  new create(env: Env) =>
    _env = env
    let command_spec =
      try
        CommandSpec.parent(
          "uring_example",
          "pony uring example program"
          where commands' = [
            CommandSpec.leaf(
              "cat",
              "output the given file to stdout"
              where args' = [
                ArgSpec.string("file", "file to print to stdout")
              ]
            )?
            CommandSpec.leaf(
              "probe",
              "check uring capabilities of the current system and report them to stdout"
            )?
          ]
        )? .> add_help()?
      else
        _env.exitcode(1)
        return
      end
    let cmd =
      match CommandParser(command_spec).parse(_env.args, _env.vars)
      | let c: Command => c
      | let ch: CommandHelp =>
        ch.print_help(_env.out)
        _env.exitcode(0)
        return
      | let se: SyntaxError =>
        _env.err.print(se.string())
        _env.exitcode(1)
        return
      end
    match cmd.spec().name()
    | "cat" =>
      let path =FilePath.create(FileAuth(_env.root), cmd.arg("file").string(), FileCaps .> set(FileRead))
      cat_cmd(path)
    | "probe" =>
      probe_cmd()
    end

  be cat_cmd(file_path: FilePath) =>
    ifdef linux then
      try
        let ring = uring.InitURing(128)?
        let config = uring.FileReaderConfig.create(
          file_path
          where chunk_size' = 100,
                nr_chunks'  = 2
        )
        let reader = uring.FileReader.create(
          config,
          ring,
          FilePrintNotify.create(_env.out, ring)
        )
      else
        _env.err.print("io_uring setup failed.")
      end
    else
      _env.err.print("Not a linux system")
    end

  be probe_cmd() =>
    ifdef linux then
      try
        let ring = uring.InitURing(128)?
        try
          let probe = uring.UringProbe.create()?
          let f = FilePath(FileAuth(_env.root), "/proc/sys/kernel/osrelease")
          match OpenFile(f)
          | let file: File =>
            let kernel_release = file.lines().next()?
            _env.out.print("io_uring on Kernel " + consume kernel_release)
          else
            _env.err.print("Unable to detect kernel version")
          end
          let header = Format("OPCODE" where width = 30, align = AlignLeft)
          header.append("SUPPORTED")
          _env.out.print(consume header)
          _env.out.print(Format("=" where width = 39, fill = '='))

          for op in uring.OpKinds().values() do
            let s = Format(op.string() where width = 30, align = AlignLeft)
            if probe.op_supported(op) then
              s.append("\u2705")
            else
              s.append("\u274C")
            end
            _env.out.print(consume s)
          end
          let nop = uring.OpNop.create()
          let that: uring.URingNotify tag = this
          _ring = ring
          ring.submit_op(consume nop, that)
        else
          _env.err.print("probe setup failed")
        end
      else
        _env.err.print("io_uring setup failed.")
      end
    else
      _env.err.print("Not a linux system")
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
    None

  fun ref on_err(errno: I32) =>
    _out.print("ERROR: " + errno.string())
    _ring.dispose()

  fun ref on_close() =>
    _ring.dispose()


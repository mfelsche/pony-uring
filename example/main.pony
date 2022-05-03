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
              "output the given file to stdout",
              [
                OptionSpec.bool("sqpoll", "Use SQPOLL"
                  where default' = true
                )
              ],
              [
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
      let sqpoll = cmd.option("sqpoll").bool()
      cat_cmd(path, sqpoll)
    | "probe" =>
      probe_cmd()
    end

  be cat_cmd(file_path: FilePath, sqpoll: Bool) =>
    ifdef linux then
      try
        var setup_flags = uring.SetupFlags.create()
        if sqpoll then
          setup_flags = setup_flags.add(uring.SetupSqPoll)
        end
        let ring = uring.InitURing(128, consume setup_flags)?
        let out_stream = uring.URingOutStream.stdout(ring)
        let reader = uring.FileInputStream.create(
          file_path,
          ring
          where
          offset' = 0,
          input_notify = FilePrintNotify.create(out_stream, ring),
          error_notify = FilePrintErrorNotify.create(_env.err)
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

class iso FilePrintNotify is InputNotify
  let _out: OutStream
  let _ring: uring.URing

  new iso create(out: OutStream, ring: uring.URing) =>
    _out = out
    _ring = ring

  fun ref apply(data: Array[U8] iso) =>
    let s = recover val String.from_iso_array(consume data) end
    _out.write(s)

  fun ref dispose() =>
    _ring.dispose()

class iso FilePrintErrorNotify is uring.ErrorNotify
  let _err: OutStream

  new iso create(err: OutStream) =>
    _err = err

  fun ref on_err(errno: I32) =>
    _err.print("ERROR: " + errno.string())


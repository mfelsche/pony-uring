# io_uring bindings for ponylang

This library exposes [liburing](https://github.com/axboe/liburing) bindings to Pony programmers.

## Build

This lib can only be built on linux for rather obvious reasons, as io_uring is only supported on linux. I know there is some windows work going on, but that is beyond my reach. Help here is most welcome.

This lib includes `liburing` and links it statically, if you integrate this lib via [corral](https://github.com/ponylang/corral) into you Pony application. See the [example](./example) for more information.

It needs to build both `liburing` and a small pony wrapper for exposing some hidden functions via FFI for pony. Thus building Pony apps with this library requires:

  * `Make`
  * a C compiler
  * `ar` and `ranlib` (part of the `binutils` package on most systems)
  * `wget`.

## Why not integrating io_uring into the Pony runtime?

The runtime is designed around polling systems like epoll or kqueue that signal readiness for file descriptors to take certain actions. The usual way how you would do IO in pony is try to write/read, if it fails because it would block, register the fd via an asio event in the asio subsystem (Not to be confused with any C++ IO library, this is a custom pony IO abstraction). The runtime would send a special message to your actor (who created the asio event) via a behaviour called `_event_notify` and you would need to check if the event says the file descriptor is readable or writeable.

The model of io_uring is a little different in that you get true asynchronous IO operations. You don't need to try and if it won't work, it will block the thread and you gotta retry later. You just submit the operation to the kernel and at some point the kernel tells you that it completed.

The pony runtime in `libponyrt` would need to be redesigned for io_uring. At least I didn't find a good way to integrate it into the runtime.

## Example

Have a look into the [./example] directory.

Example output showing probing capabilities and a single NOP operation being submitted and completed and received:

```
io_uring on Kernel 6.2.6-76060206-generic
OPCODE                        SUPPORTED
=======================================
IORING_OP_NOP                 ✅
IORING_OP_READV               ✅
IORING_OP_WRITEV              ✅
IORING_OP_FSYNC               ✅
IORING_OP_READ_FIXED          ✅
IORING_OP_WRITE_FIXED         ✅
IORING_OP_POLL_ADD            ✅
IORING_OP_POLL_REMOVE         ✅
IORING_OP_SYNC_FILE_RANGE     ✅
IORING_OP_SENDMSG             ✅
IORING_OP_RECVMSG             ✅
IORING_OP_TIMEOUT             ✅
IORING_OP_TIMEOUT_REMOVE      ✅
IORING_OP_ACCEPT              ✅
IORING_OP_ASYNC_CANCEL        ✅
IORING_OP_LINK_TIMEOUT        ✅
IORING_OP_CONNECT             ✅
IORING_OP_FALLOCATE           ✅
IORING_OP_OPENAT              ✅
IORING_OP_CLOSE               ✅
IORING_OP_FILES_UPDATE        ✅
IORING_OP_STATX               ✅
IORING_OP_READ                ✅
IORING_OP_WRITE               ✅
IORING_OP_FADVISE             ✅
IORING_OP_MADVISE             ✅
IORING_OP_SEND                ✅
IORING_OP_RECV                ✅
IORING_OP_OPENAT2             ✅
IORING_OP_EPOLLCTL            ✅
IORING_OP_SPLICE              ✅
IORING_OP_PROVIDE_BUFFERS     ✅
IORING_OP_REMOVE_BUFFERS      ✅
IORING_OP_TEE                 ✅
IORING_OP_SHUTDOWN            ✅
IORING_OP_RENAMEAT            ✅
IORING_OP_UNLINKAT            ✅
IORING_OP_MKDIRAT             ✅
IORING_OP_SYMLINKAT           ✅
IORING_OP_LINKAT              ✅
IORING_OP_MS_RING             ✅
IORING_OP_FSETXATTR           ✅
IORING_OP_SETXATTR            ✅
IORING_OP_FGETXATTR           ✅
IORING_OP_GETXATTR            ✅
IORING_OP_SOCKET              ✅
IORING_OP_URING_CMD           ✅
Nop completed with 0
```


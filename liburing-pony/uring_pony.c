#include "liburing.h"

// probe stuff

int pony_uring_opcode_supported(const struct io_uring_probe *p, int op)
{
  return io_uring_opcode_supported(p, op);
}


// cqe stuff

void pony_uring_cqe_seen(struct io_uring * ring, struct io_uring_cqe *cqe)
{
  io_uring_cqe_seen(ring, cqe);
}

// sqe_stuff

void pony_uring_sqe_set_data(struct io_uring_sqe *sqe, void *data)
{
  io_uring_sqe_set_data(sqe, data);
}

#include "liburing.h"
#include <stddef.h>
#include <stdint.h>

// probe stuff

int pony_uring_opcode_supported(const struct io_uring_probe *p, int op)
{
  return io_uring_opcode_supported(p, op); }


// cqe stuff

// return number of ready cqe entries
unsigned pony_uring_cq_ready(const struct io_uring *ring)
{
  return io_uring_cq_ready(ring);
}

// mark the given cqe as seen and recycle it in the completion queue
void pony_uring_cqe_seen(struct io_uring * ring, struct io_uring_cqe *cqe)
{
  io_uring_cqe_seen(ring, cqe);
}

// get a cqe entry or NULL if none is ready yet
struct io_uring_cqe* pony_uring_peek_cqe(struct io_uring *ring)
{
  struct io_uring_cqe* ptr = NULL;
  if(io_uring_peek_cqe(ring, &ptr) == 0)
  {
    return ptr;
  }
  else
  {
    return NULL;
  }
}

void *pony_uring_cqe_get_data(const struct io_uring_cqe *cqe)
{
  return io_uring_cqe_get_data(cqe);
}

// sqe_stuff

void pony_uring_sqe_set_data(struct io_uring_sqe *sqe, uint64_t data)
{
  io_uring_sqe_set_data(sqe, (void*)data);
}

void pony_uring_sqe_set_flags(struct io_uring_sqe *sqe, uint8_t flags)
{
  sqe->flags |= flags;
}

void pony_uring_prep_nop(struct io_uring_sqe *sqe)
{
  io_uring_prep_nop(sqe);
}

void pony_uring_prep_read(struct io_uring_sqe *sqe,
                            int fd,
                            void* buf,
                            unsigned nbytes,
                            uint64_t offset)
{
  io_uring_prep_read(sqe, fd, buf, nbytes, offset);
}

void pony_uring_prep_readv(struct io_uring_sqe *sqe,
                            int fd,
                            const struct iovec *iovecs,
                            unsigned nr_vecs,
                            uint64_t offset)
{
  io_uring_prep_readv(sqe, fd, iovecs, nr_vecs, offset);
}

void pony_uring_prep_writev(struct io_uring_sqe *sqe,
                            int fd,
                            const struct iovec *iovecs,
                            unsigned nr_vecs,
                            uint64_t offset)
{
  io_uring_prep_writev(sqe, fd, iovecs, nr_vecs, offset);
}

void pony_uring_prep_fsync(struct io_uring_sqe *sqe, int fd, unsigned fsync_flags)
{
  io_uring_prep_fsync(sqe, fd, fsync_flags);
}

void pony_uring_prep_close(struct io_uring_sqe *sqe, int fd)
{
  io_uring_prep_close(sqe, fd);
}

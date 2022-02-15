ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

LIBURING_VERSION := liburing-2.1
LIBURING_DIR := $(ROOT_DIR)/liburing-$(LIBURING_VERSION)
LIBURING_INCLUDE_DIR := "$(ROOT_DIR)/liburing-$(LIBURING_VERSION)/src/include"
LIBURING_LIB := $(ROOT_DIR)/liburing.a

LIBURING_PONY_DIR := $(ROOT_DIR)/liburing-pony
LIBURING_PONY_LIB := $(ROOT_DIR)/liburing_pony.a

CFLAGS ?= -g -fomit-frame-pointer -O2
override CFLAGS += -D_GNU_SOURCE \
	-Wall -Wextra -Wno-unused-parameter -Wno-sign-compare -I$(LIBURING_INCLUDE_DIR)


.ONESHELL:

all: liburing_pony

### LIBURING ###

liburing: $(LIBURING_LIB)

$(LIBURING_DIR):
	wget -c https://github.com/axboe/liburing/archive/refs/tags/$(LIBURING_VERSION).tar.gz -O - | tar xz

$(LIBURING_LIB): $(LIBURING_DIR)
	$(MAKE) -C $(LIBURING_DIR)
	cp $(LIBURING_DIR)/src/liburing.a $(LIBURING_LIB)

### LIBURING_PONY ###
liburing_pony: $(LIBURING_LIB) $(LIBURING_PONY_LIB)

liburing_pony_srcs := $(LIBURING_PONY_DIR)/uring_pony.c
liburing_pony_objs := $(patsubst %.c,%.ol,$(liburing_pony_srcs))

%.ol: %.c
	$(QUIET_CC)$(CC) $(CFLAGS) -c -o $@ $<

AR ?= ar
RANLIB ?= ranlib
$(LIBURING_PONY_LIB): $(liburing_pony_objs)
	@rm -f $(LIBURING_PONY_LIB)
	$(AR) r $(LIBURING_PONY_LIB) $^
	$(RANLIB) $(LIBURING_PONY_LIB)

clean:
	rm -rf $(LIBURING_DIR) $(LIBURING_LIB) $(LIBURING_PONY_LIB) $(LIBURING_PONY_DIR)/*.a $(LIBURING_PONY_DIR)/*.ol

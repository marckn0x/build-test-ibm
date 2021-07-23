#!/bin/sh -e

# Hidden dependencies:
# * pkg-config
# * glib2
# * autoconf
# * automake
# * gettext
# * pixman

set -e

cd $(dirname $0)
cd qemu_stm32

ARGS=""
ARGS="$ARGS --target-list="arm-softmmu""
ARGS="$ARGS --disable-werror"
ARGS="$ARGS --enable-debug"
ARGS="$ARGS --disable-glusterfs"

if [ -n "$PREFIX" ]; then
  ARGS="$ARGS --prefix=$PREFIX"
fi

if [ -n "$DEBUG_STM32" ]; then
  ARGS="$ARGS --extra-cflags=-DDEBUG_STM32_RCC"
  ARGS="$ARGS --extra-cflags=-DDEBUG_STM32_UART"
  ARGS="$ARGS --extra-cflags=-DDEBUG_STM32_TIMER"
fi

./configure $ARGS
make -j4
make install

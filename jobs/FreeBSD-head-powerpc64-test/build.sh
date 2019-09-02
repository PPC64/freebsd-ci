#!/bin/sh

export TARGET=powerpc
export TARGET_ARCH=powerpc64

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
run-kyua.sh
"

sh -x ./run-tests.sh

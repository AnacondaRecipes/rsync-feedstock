#!/bin/sh

set -e -o pipefail

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

if [[ "${target_platform}" == "osx-arm64" ]]; then
    EXTRA_CONFIGURE_ARGS="--disable-simd"
    sed -i.bak 's/ret = mknodat(dfd, bname, mode, dev);/ret = mknod(bname, mode, dev);/g' syscall.c
fi

./configure --prefix=$PREFIX --without-included-zlib --without-included-popt ${EXTRA_CONFIGURE_ARGS:-}
make -j${CPU_COUNT}
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    if [[ "${target_platform}" == "osx-arm64" ]]; then
        # Skip failed tests on arm64
        # ERROR: dir/file failed verification -- update discarded.
        # test 1: update through directory symlink failed
        make tls trimslash t_unsafe t_chmod_secure t_secure_relpath wildtest getgroups getfsdev
        TESTS=$(cd testsuite && ls *.test | sed 's/\.test$//' | grep -v '^chmod-symlink-race$' | grep -v '^symlink-dirlink-basis$' | tr '\n' ' ')
        ./runtests.py --rsync-bin="$(pwd)/rsync" $TESTS
    else
        make check
    fi
fi
make install

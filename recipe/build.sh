#!/bin/sh

set -e -o pipefail

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

if [[ "${target_platform}" == "osx-arm64" ]]; then
    EXTRA_CONFIGURE_ARGS="--disable-simd"
fi
# mknodat not declared in macOS SDK 12.1 headers with clang 20
if [[ "${target_platform}" == osx-* ]]; then
    export ac_cv_func_mknodat=no
fi

./configure --prefix=$PREFIX --without-included-zlib --without-included-popt ${EXTRA_CONFIGURE_ARGS:-}
make -j${CPU_COUNT}
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    make check
fi
make install

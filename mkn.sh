#!/usr/bin/env bash
set -e
THREADS=${THREADS:=""}
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="raja"
GIT_URL="https://github.com/llnl/$DIR"
VERSION="develop"
FFF=("include" "lib" "$DIR" "share")
[ ! -z "$MKN_CLEAN" ] && (( $MKN_CLEAN == 1 )) && for f in ${FFF[@]}; do rm -rf $CWD/$f; done
[ ! -d "$CWD/$DIR" ] && git clone --depth 1 $GIT_URL -b $VERSION $DIR --recursive
cd $CWD/$DIR
rm -rf build && mkdir build && cd build

# see http://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards
CUDA_ARCH="sm_61" # 61 = gtx 1080
CLANG_CUDA_EXTRA=""
CMAKE_CXX_FLAGS="-g0 -O3 -march=native -mtune=native"

## for CLANG_CUDA , both ENABLE_CUDA and ENABLE_CLANG_CUDA must be "ON"
## and uncomment next line
# CLANG_CUDA_EXTRA="-x cuda --cuda-gpu-arch=${CUDA_ARCH}"

cmake .. \
  -DRAJA_ENABLE_EXAMPLES=OFF                  \
  -DENABLE_EXAMPLES=OFF                       \
  -DENABLE_TESTS=OFF                          \
  -DENABLE_OPENMP=OFF \
  -DCMAKE_INSTALL_PREFIX=$CWD \
  -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true \
  -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_CUDA=ON -DCUDA_ARCH=${CUDA_ARCH} -DBLT_CLANG_CUDA_ARCH=${CUDA_ARCH} \
  -DENABLE_CLANG_CUDA=OFF \
  -DCMAKE_CUDA_FLAGS="${CLANG_CUDA_EXTRA}" \
  -DENABLE_HIP=OFF  -DBUILD_SHARED_LIBS=ON

make VERBOSE=1 -j$THREADS && make install
cd .. && rm -rf build

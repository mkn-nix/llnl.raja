#!/usr/bin/env bash
set -e
THREADS=${THREADS:=""}
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="raja"
GIT_URL="https://github.com/llnl/$DIR"
# pinned: released before SAMRAI v-4-6-1, keep in step with llnl.umpire phare branch
VERSION=${VERSION:="v2026.07.1"}
FFF=("include" "lib" "$DIR" "share")
[ ! -z "$MKN_CLEAN" ] && (( $MKN_CLEAN == 1 )) && for f in ${FFF[@]}; do rm -rf $CWD/$f; done
[ ! -d "$CWD/$DIR" ] && git clone --depth 1 $GIT_URL -b $VERSION $DIR --recursive
cd $CWD/$DIR
HAVE=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
[ "$HAVE" != "$VERSION" ] && echo "$CWD/$DIR is $HAVE, not $VERSION: rerun with MKN_CLEAN=1" && exit 1
rm -rf build && mkdir build && cd build

# see https://developer.nvidia.com/cuda-gpus - 120 = RTX 5080, needs CUDA >= 12.8
CUDA_ARCH=${CUDA_ARCH:="120"}
CMAKE_CXX_FLAGS="-g0 -O3 -march=native -mtune=native"

cmake .. \
  -DRAJA_ENABLE_EXAMPLES=OFF -DRAJA_ENABLE_EXERCISES=OFF -DRAJA_ENABLE_TESTS=OFF \
  -DENABLE_EXAMPLES=OFF -DENABLE_TESTS=OFF -DENABLE_DOCS=OFF \
  -DENABLE_OPENMP=OFF \
  -DCMAKE_INSTALL_PREFIX=$CWD -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true \
  -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" \
  -DCMAKE_BUILD_TYPE=Release -DBLT_CXX_STD=c++20 \
  -DENABLE_CUDA=ON -DRAJA_ENABLE_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCH} \
  -DENABLE_HIP=OFF -DBUILD_SHARED_LIBS=ON

make VERBOSE=1 -j$THREADS && make install
cd .. && rm -rf build

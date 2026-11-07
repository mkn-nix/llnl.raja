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

# see http://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards
CUDA_ARCH=${CUDA_ARCH:="sm_120"} # 120 = RTX 5080, needs CUDA >= 12.8
CUDA_HOME=${CUDA_HOME:="/usr/local/cuda"}
CLANG_CUDA_EXTRA=""
CMAKE_CXX_FLAGS="-g0 -O3 -march=native -mtune=native -Wno-unknown-cuda-version"

## for CLANG_CUDA , both ENABLE_CUDA and BLT_ENABLE_CLANG_CUDA must be "ON"
## clang only, no nvcc: BLT adds "-x cuda --cuda-gpu-arch" itself, extra flags go here
# CLANG_CUDA_EXTRA="-x cuda --cuda-gpu-arch=${CUDA_ARCH}"

cmake .. \
  -DRAJA_ENABLE_EXAMPLES=OFF -DRAJA_ENABLE_EXERCISES=OFF -DRAJA_ENABLE_TESTS=OFF \
  -DENABLE_EXAMPLES=OFF -DENABLE_TESTS=OFF -DENABLE_DOCS=OFF \
  -DENABLE_OPENMP=OFF \
  -DCMAKE_INSTALL_PREFIX=$CWD -DCMAKE_INSTALL_LIBDIR:PATH=lib \
  -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true \
  -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" \
  -DCMAKE_BUILD_TYPE=Release -DBLT_CXX_STD=c++20 \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DENABLE_CUDA=ON -DRAJA_ENABLE_CUDA=ON -DCUDA_ARCH=${CUDA_ARCH} -DBLT_CLANG_CUDA_ARCH=${CUDA_ARCH} \
  -DBLT_ENABLE_CLANG_CUDA=ON -DENABLE_CLANG_CUDA=ON -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} \
  -DCMAKE_CUDA_COMPILE_FEATURES=cuda_std_20 \
  -DCMAKE_CUDA_FLAGS="${CLANG_CUDA_EXTRA}" \
  -DENABLE_HIP=OFF  -DBUILD_SHARED_LIBS=ON

make VERBOSE=1 -j$THREADS && make install
cd .. && rm -rf build

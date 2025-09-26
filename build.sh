#!/bin/bash

set -e -x

BUILD_DIR=$(pwd)

echo "LLVM_VERSION = $LLVM_VERSION"
echo "TARGET_TRIPLE = $TARGET_TRIPLE"
echo "INSTALL_PREFIX = $INSTALL_PREFIX"
echo "SUDO_CMD = $SUDO_CMD"
echo "PYTHON_EXE = $PYTHON_EXE"
echo "PATH=$PATH"
which g++
g++ --version
which make
make --version
which cmake
cmake --version
which python
python --version

# download LLVM source code
git clone -b $LLVM_VERSION --depth 1 https://github.com/llvm/llvm-project.git
cd llvm-project/llvm

# make build dir and run cmake
mkdir build
cd build
cmake -GNinja .. \
    -DPython3_EXECUTABLE=$PYTHON_EXE \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DLLVM_DEFAULT_TARGET_TRIPLE=$TARGET_TRIPLE \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DLLVM_TARGETS_TO_BUILD="$LLVM_TARGETS_TO_BUILD" \
    -DLLVM_BUILD_TOOLS=OFF \
    -DLLVM_INCLUDE_TOOLS=OFF \
    -DLLVM_BUILD_EXAMPLES=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_BUILD_TESTS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_BUILD_UTILS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_INCLUDE_GO_TESTS=OFF \
    -DLLVM_BUILD_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_ENABLE_LIBPFM=OFF \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_DIA_SDK=OFF \
    -DLLVM_BUILD_INSTRUMENTED_COVERAGE=OFF \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_WARNINGS=OFF \
    -DLLVM_ENABLE_Z3_SOLVER=OFF
ls
time ninja
$SUDO_CMD ninja install

ccache --show-stats

cd ../../..
mkdir artefacts
cd artefacts
tar -zcvf sme_deps_llvm_$OS.tgz $INSTALL_PREFIX/*

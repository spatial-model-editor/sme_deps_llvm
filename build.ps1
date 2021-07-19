echo "LLVM_VERSION = $env:LLVM_VERSION"
echo "TARGET_TRIPLE = $env:TARGET_TRIPLE"
echo "INSTALL_PREFIX = $env:INSTALL_PREFIX"

# download LLVM source code
mkdir llvm
$client = New-Object System.Net.WebClient
$client.DownloadFile("https://github.com/llvm/llvm-project/releases/download/llvmorg-$env:LLVM_VERSION/llvm-$env:LLVM_VERSION.src.tar.xz", "C:\llvm.tar.xz")
7z x C:\llvm.tar.xz
7z x llvm.tar
mv llvm-$env:LLVM_VERSION.src/* llvm
cd llvm

# make build dir and run cmake
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX" `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLVM_DEFAULT_TARGET_TRIPLE="$env:TARGET_TRIPLE" `
  -DLLVM_TARGETS_TO_BUILD="X86" `
  -DLLVM_BUILD_TOOLS=OFF `
  -DLLVM_INCLUDE_TOOLS=OFF `
  -DLLVM_BUILD_EXAMPLES=OFF `
  -DLLVM_INCLUDE_EXAMPLES=OFF `
  -DLLVM_BUILD_TESTS=OFF `
  -DLLVM_INCLUDE_TESTS=OFF `
  -DLLVM_INCLUDE_DOCS=OFF `
  -DLLVM_BUILD_UTILS=OFF `
  -DLLVM_INCLUDE_UTILS=OFF `
  -DLLVM_INCLUDE_GO_TESTS=OFF `
  -DLLVM_BUILD_BENCHMARKS=OFF `
  -DLLVM_INCLUDE_BENCHMARKS=OFF `
  -DLLVM_ENABLE_LIBPFM=OFF `
  -DLLVM_ENABLE_ZLIB=OFF `
  -DLLVM_ENABLE_DIA_SDK=OFF `
  -DLLVM_BUILD_INSTRUMENTED_COVERAGE=OFF `
  -DLLVM_ENABLE_BINDINGS=OFF `
  -DLLVM_ENABLE_RTTI=ON `
  -DLLVM_ENABLE_TERMINFO=OFF `
  -DLLVM_ENABLE_LIBXML2=OFF `
  -DLLVM_ENABLE_WARNINGS=OFF `
  -DLLVM_ENABLE_Z3_SOLVER=OFF

cmake --build . --parallel

cmake --install .

cd ..\..
mkdir artefacts
cd artefacts
7z a tmp.tar $env:INSTALL_PREFIX
7z a sme_deps_llvm_$env:OS.tgz tmp.tar
rm tmp.tar

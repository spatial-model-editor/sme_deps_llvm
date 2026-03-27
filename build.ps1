Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($PSVersionTable.PSVersion.Major -ge 7) {
  $PSNativeCommandUseErrorActionPreference = $true
}

function New-Directory {
  param([Parameter(Mandatory)] [string]$Path)
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

$requiredEnvVars = @(
  "LLVM_VERSION",
  "TARGET_TRIPLE",
  "INSTALL_PREFIX",
  "PYTHON_EXE",
  "OS",
  "LLVM_TARGETS_TO_BUILD"
)

foreach ($name in $requiredEnvVars) {
  if (-not (Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue)) {
    throw "$name is not set"
  }
}

$buildTag = if ($env:BUILD_TAG) { $env:BUILD_TAG } else { "" }
$pythonExe = (Get-Command $env:PYTHON_EXE -ErrorAction Stop).Source

if (-not $env:CMAKE_MSVC_RUNTIME_LIBRARY) {
  $env:CMAKE_MSVC_RUNTIME_LIBRARY = 'MultiThreaded$<$<CONFIG:Debug>:Debug>'
}
if (-not $env:LLVM_USE_CRT_RELEASE) {
  $env:LLVM_USE_CRT_RELEASE = "MT"
}

Write-Host "LLVM_VERSION = $env:LLVM_VERSION"
Write-Host "TARGET_TRIPLE = $env:TARGET_TRIPLE"
Write-Host "LLVM_USE_SANITIZER = $env:LLVM_USE_SANITIZER"
Write-Host "INSTALL_PREFIX = $env:INSTALL_PREFIX"
Write-Host "BUILD_TAG = $buildTag"
Write-Host "SUDO_CMD = $env:SUDO_CMD"
Write-Host "PYTHON_EXE = $pythonExe"
Write-Host "CMAKE_MSVC_RUNTIME_LIBRARY = $env:CMAKE_MSVC_RUNTIME_LIBRARY"
Write-Host "LLVM_USE_CRT_RELEASE = $env:LLVM_USE_CRT_RELEASE"
Write-Host "PATH=$env:PATH"
Write-Host "git = $((Get-Command git -ErrorAction Stop).Source)"
git --version
Write-Host "cl = $((Get-Command cl -ErrorAction Stop).Source)"
Write-Host "ninja = $((Get-Command ninja -ErrorAction Stop).Source)"
ninja --version
Write-Host "cmake = $((Get-Command cmake -ErrorAction Stop).Source)"
cmake --version
Write-Host "python = $pythonExe"
& $pythonExe --version

# download LLVM source code
git clone -b "llvmorg-$env:LLVM_VERSION" --depth 1 https://github.com/llvm/llvm-project.git
Push-Location "llvm-project\llvm"

# make build dir and run cmake
New-Directory "build"
Push-Location "build"
$cmakeArgs = @(
  "-GNinja",
  "..",
  "-DPython3_EXECUTABLE=$pythonExe",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DCMAKE_MSVC_RUNTIME_LIBRARY=$env:CMAKE_MSVC_RUNTIME_LIBRARY",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
  "-DCMAKE_CXX_VISIBILITY_PRESET=hidden",
  "-DLLVM_DEFAULT_TARGET_TRIPLE=$env:TARGET_TRIPLE",
  "-DLLVM_USE_CRT_RELEASE=$env:LLVM_USE_CRT_RELEASE"
)

if ($env:MACOSX_DEPLOYMENT_TARGET) {
  $cmakeArgs += "-DCMAKE_OSX_DEPLOYMENT_TARGET=$env:MACOSX_DEPLOYMENT_TARGET"
}

$cmakeArgs += @(
  "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache",
  "-DLLVM_TARGETS_TO_BUILD=$env:LLVM_TARGETS_TO_BUILD",
  "-DLLVM_BUILD_TOOLS=OFF",
  "-DLLVM_INCLUDE_TOOLS=OFF",
  "-DLLVM_BUILD_EXAMPLES=OFF",
  "-DLLVM_INCLUDE_EXAMPLES=OFF",
  "-DLLVM_BUILD_TESTS=OFF",
  "-DLLVM_INCLUDE_TESTS=OFF",
  "-DLLVM_INCLUDE_DOCS=OFF",
  "-DLLVM_BUILD_UTILS=OFF",
  "-DLLVM_INCLUDE_UTILS=OFF",
  "-DLLVM_INCLUDE_GO_TESTS=OFF",
  "-DLLVM_BUILD_BENCHMARKS=OFF",
  "-DLLVM_INCLUDE_BENCHMARKS=OFF",
  "-DLLVM_ENABLE_LIBPFM=OFF",
  "-DLLVM_ENABLE_ZLIB=OFF",
  "-DLLVM_ENABLE_ZSTD=OFF",
  "-DLLVM_ENABLE_DIA_SDK=OFF",
  "-DLLVM_BUILD_INSTRUMENTED_COVERAGE=OFF",
  "-DLLVM_ENABLE_BINDINGS=OFF",
  "-DLLVM_ENABLE_RTTI=ON",
  "-DLLVM_ENABLE_TERMINFO=OFF",
  "-DLLVM_ENABLE_LIBXML2=OFF",
  "-DLLVM_ENABLE_WARNINGS=OFF",
  "-DLLVM_ENABLE_Z3_SOLVER=OFF",
  "-DLLVM_USE_SANITIZER=$env:LLVM_USE_SANITIZER"
)

cmake @cmakeArgs
Get-ChildItem
ninja
if ($env:SUDO_CMD) {
  & $env:SUDO_CMD ninja install
} else {
  ninja install
}
Pop-Location
Pop-Location

ccache --show-stats

# make tarball of installation
New-Directory "artefacts"
Push-Location "artefacts"
7z a "tmp.tar" $env:INSTALL_PREFIX
7z a "sme_deps_llvm_$($env:OS)$buildTag.tgz" "tmp.tar"
Remove-Item "tmp.tar"
Pop-Location

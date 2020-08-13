#!/bin/bash
source source.sh

echo "Continuing existing build.."
# continue existing cached partial build
cd llvm/build
time make -j2
$SUDO_CMD make install
cd ../..
echo "Build complete."

#!/bin/bash
source source.sh

echo "Continuing existing build.."
# continue existing cached partial build
cd llvm/build
time $MAKE_PROGRAM -j2
$MAKE_INSTALL
cd ../..
echo "Build complete."

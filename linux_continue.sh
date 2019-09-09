echo "Continuing existing build.."
# continue existing cached partial build
cd llvm/build
time make -j2
make install
cd ../..
echo "Build complete."

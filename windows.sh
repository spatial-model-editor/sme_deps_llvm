# make sure we get the right mingw64 version of g++ on appveyor
PATH=/mingw64/bin:$PATH

which cmake
which g++
which python
gcc --version
g++ --version

test -f llvm/SETUP_COMPLETE || bash windows_setup.sh

cd llvm/build
make -j2
make install
cd ../../


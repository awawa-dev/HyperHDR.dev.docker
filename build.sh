#/bin/sh
mkdir ccache
cd ccache
wget https://github.com/ccache/ccache/releases/download/v4.1/ccache-4.1.tar.gz
tar -zxvf ccache-4.1.tar.gz
cd ccache-4.1
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
if [ "$?" -ne "0" ]; then
  echo "CMake config failed"
  exit 1
fi
make
if [ "$?" -ne "0" ]; then
  echo "Make failed"
  exit 1
fi
make install
if [ "$?" -ne "0" ]; then
  echo "Make install failed"
  exit 1
fi
cd ../../..
rm -r ccache
if [ "$?" -ne "0" ]; then
  echo "Clean up failed"
  exit 1
fi


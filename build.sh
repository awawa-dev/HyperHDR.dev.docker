#/bin/sh

if cmake --version | grep -q '3.16.3'; then
  apt update
  apt remove cmake cmake-data
  apt install cmake=3.13.4-1 cmake-data=3.13.4-1
fi	

mkdir ccache
cd ccache

wget https://github.com/ccache/ccache/releases/download/v4.4.1/ccache-4.4.1.tar.gz
if [ "$?" -ne "0" ]; then
  echo "Could not download ccache sources"
  exit 1
fi

tar -zxvf ccache-4.4.1.tar.gz
if [ "$?" -ne "0" ]; then
  echo "Extracting of ccache failed"
  exit 1
fi

cd ccache-4.4.1
if [ "$?" -ne "0" ]; then
  echo "Missing ccache folder"
  exit 1
fi

mkdir build
cd build
cmake -DHIREDIS_FROM_INTERNET=ON -DCMAKE_BUILD_TYPE=Release ..
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


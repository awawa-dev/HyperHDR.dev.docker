#/bin/sh
mkdir ccache
cd ccache

wget https://github.com/ccache/ccache/releases/download/v4.2/ccache-4.2.tar.gz
if [ "$?" -ne "0" ]; then
  echo "Could not download ccache sources"
  exit 1
fi

tar -zxvf ccache-4.2.tar.gz
if [ "$?" -ne "0" ]; then
  echo "Extracting of ccache failed"
  exit 1
fi

cd ccache-4.2
if [ "$?" -ne "0" ]; then
  echo "Missing ccache folder"
  exit 1
fi

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


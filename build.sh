#!/bin/bash

# ICU

ICUDATA=$(find /usr -name libicudata.so)
ICUDATA=`echo ${ICUDATA} | head -1`

if [ ! -z "${ICUDATA}" ]; then
	echo ${ICUDATA}
	OLDICU=$(readlink "${ICUDATA}")
	OLDICU_FILE=$(readlink -f "${ICUDATA}")
	echo ${OLDICU}
	ls -la ${OLDICU_FILE}
	IFS='.'
  read -r -a array <<< $OLDICU
	IFS=$' \t\n'

	if [ "${array[0]}" == "libicudata" ]; then
		mkdir ICU
		pushd ICU

		ICU_MAJOR_VERSION=${array[2]}
		ICU_MINOR_VERSION=${array[3]}
		echo "ICU_MAJOR_VERSION=${ICU_MAJOR_VERSION}"
		echo "ICU_MINOR_VERSION=${ICU_MINOR_VERSION}"

		wget https://github.com/unicode-org/icu/releases/download/release-${ICU_MAJOR_VERSION}-${ICU_MINOR_VERSION}/icu4c-${ICU_MAJOR_VERSION}_${ICU_MINOR_VERSION}-src.tgz
		wget https://github.com/unicode-org/icu/releases/download/release-${ICU_MAJOR_VERSION}-${ICU_MINOR_VERSION}/icu4c-${ICU_MAJOR_VERSION}_${ICU_MINOR_VERSION}-data.zip

		tar -xvzf ./icu4c-${ICU_MAJOR_VERSION}_${ICU_MINOR_VERSION}-src.tgz
		rm -rf ./icu/source/data
		unzip icu4c-${ICU_MAJOR_VERSION}_${ICU_MINOR_VERSION}-data.zip -d ./icu/source
		echo '{"localeFilter": {"filterType": "language","whitelist": ["en"]}}' > filters.json
		ICU_DATA_FILTER_FILE=filters.json ./icu/source/runConfigureICU Linux
		make -j $(nproc)
		mv -f lib/libicudata.so.${ICU_MAJOR_VERSION}.${ICU_MINOR_VERSION} ${OLDICU_FILE}
		ls -la ${OLDICU_FILE}

		popd
		rm -rf ICU
	else
		echo "Not a libicudata: ${array[0]}"
	fi
else
	echo "Could not find libicudata"
fi


# CMAKE

if cmake --version | grep -q '3.16.3'; then
  apt update
  apt remove cmake cmake-data
  apt install cmake=3.13.4-1 cmake-data=3.13.4-1
fi

# build and install ccache
ccache_version="4.10.1"

mkdir ccache
cd ccache

wget "https://github.com/ccache/ccache/releases/download/v${ccache_version}/ccache-${ccache_version}.tar.gz"
if [ "$?" -ne "0" ]; then
  echo "Could not download ccache sources"
  exit 1
fi

tar -zxvf "ccache-${ccache_version}.tar.gz"
if [ "$?" -ne "0" ]; then
  echo "Extracting of ccache failed"
  exit 1
fi

cd "ccache-${ccache_version}"
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
make -j $(nproc)
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


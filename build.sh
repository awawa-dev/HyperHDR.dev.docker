#!/bin/bash

# QT 6.8 LTS
qt_version="6.8.3"
echo "export Qt6_DIR=/usr/local/Qt-${qt_version}/lib/cmake/Qt6/" >> /etc/profile
git clone --branch v${qt_version} https://github.com/qt/qtbase.git qt_lts
mkdir qt_build
cd qt_build
../qt_lts/configure -submodules qtbase,qtnetwork,qtserialport -no-sbom -no-dbus -no-gui -no-widgets -no-sql-sqlite -no-icu -skip qtsql -skip qtxml -nomake tests -nomake examples
if [ "$?" -ne "0" ]; then
  echo "Qt configuration failed"
  exit 1
fi
cmake --build . --parallel
if [ "$?" -ne "0" ]; then
  echo "Qt build failed"
  exit 1
fi
cmake --install .
if [ "$?" -ne "0" ]; then
  echo "Qt install failed"
  exit 1
fi

cd ..
rm -r qt_lts
if [ "$?" -ne "0" ]; then
  echo "Qt clean failed (1)"
  exit 1
fi
rm -r qt_build
if [ "$?" -ne "0" ]; then
  echo "Qt clean failed (2)"
  exit 1
fi

# CCACHE
ccache_version="4.11.3"

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

exit 0

# ICU
echo '------------------------------------------------- find libicudata -------------------------------------------------'
for file in `find / -name libicu* -type f,l`; do echo $file; ls -la $file;done
echo '------------------------------------------------- find libicudata -------------------------------------------------'
ICUDATA=$(find /usr -name libicudata.so -type f,l)
ICUDATA=`echo ${ICUDATA} | head -1`

if [ -z "${ICUDATA}" ]; then
	ICUDATA=$(find /usr -name libicudata.so.?? -type f,l)
	ICUDATA=`echo ${ICUDATA} | head -1`
fi

if [ ! -z "${ICUDATA}" ]; then
	ICUDATADIR=$(dirname "${ICUDATA}")
	OLDICU=$(readlink "${ICUDATA}")
	OLDICU_FILE=$(readlink -f "${ICUDATA}")

	echo '--------------------------------------------- getting info libicudata ---------------------------------------------'
	echo "ICUDATA = ${ICUDATA}"
	echo "ICUDATADIR = ${ICUDATADIR}"
	echo "OLDICU = ${OLDICU}"
	echo "OLDICU_FILE = ${OLDICU_FILE}"
	ls -la ${ICUDATADIR}/libicudata*

	echo '--------------------------------------------- getting ldd libicudata ----------------------------------------------'
	ldd --verbose ${OLDICU_FILE}
	objdump -f ${OLDICU_FILE} || exit 0

	echo '----------------------------------------------------- building libicudata -----------------------------------------'
	
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
		sed -i "s/LDFLAGSICUDT=-nodefaultlibs -nostdlib/LDFLAGSICUDT=/g" ./icu/source/config/mh-linux
		echo '{"localeFilter": {"filterType": "language","whitelist": ["en"]}}' > filters.json
		ICU_DATA_FILTER_FILE=filters.json ./icu/source/runConfigureICU Linux --enable-static
		make -j $(nproc)

		echo '------------------------------------------- replacing libicudata --------------------------------------------------'		
		ls -la ${ICUDATADIR}/libicudata*		
		rm -f ${ICUDATADIR}/libicudata.so
		rm -f ${ICUDATADIR}/libicudata.so.${ICU_MAJOR_VERSION}
		rm -f ${OLDICU_FILE}

		echo '-------------------------------------------------------------------------------------------------------------------'				
		ls -la lib/*

		FINAL_ICUDATA="libicudata.so.${ICU_MAJOR_VERSION}.${ICU_MINOR_VERSION}"
		cp lib/${FINAL_ICUDATA} ${OLDICU_FILE}
		ln -s ${FINAL_ICUDATA} ${ICUDATADIR}/libicudata.so
		ln -s ${FINAL_ICUDATA} ${ICUDATADIR}/libicudata.so.${ICU_MAJOR_VERSION}

		echo '-------------------------------------------------------------------------------------------------------------------'		
		ls -la ${ICUDATADIR}/libicudata*
		
		rm /etc/ld.so.cache
		ldconfig -v || exit 0
		echo '------------------------------------------- replacing libicudata --------------------------------------------------'

		popd
		rm -rf ICU

		echo '--------------------------------------------- purge ldconfig ------------------------------------------------------'
		rm /etc/ld.so.cache
		ldconfig -v || exit 0
		echo '-------------------------------------------- verifying libicudata -------------------------------------------------'
		ldd --verbose ${ICUDATADIR}/libicudata.so

		echo '--------------------------------------------'
		ldd --verbose ${ICUDATADIR}/libicudata.so.${ICU_MAJOR_VERSION}

		echo '--------------------------------------------'
		ldd --verbose ${ICUDATADIR}/libicudata.so.${ICU_MAJOR_VERSION}.${ICU_MINOR_VERSION}
		objdump -f ${ICUDATADIR}/libicudata.so.${ICU_MAJOR_VERSION}.${ICU_MINOR_VERSION} || exit 0

		echo '-------------------------------------------- verifying libicudata -------------------------------------------------'
	else
		echo "Not a libicudata: ${array[0]}"
	fi
else
	echo "Could not find libicudata"
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

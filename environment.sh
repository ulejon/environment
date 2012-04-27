#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$BASH_SOURCE")" && pwd)
if [ -z "`echo $PATH | grep ${SCRIPT_DIR}`" ]; then
        export PATH=${PATH}:${SCRIPT_DIR}
fi
function deploytest() {
	FILE_LIST=("tests/ear/target/paysol-*.ear" "core/security/target/paysol-*[^sources].jar"  )
	deployInternal $@
}


function deploy() {
	FILE_LIST=("core/ear/target/paysol-*.ear" "core/security/target/paysol-*[^sources].jar"  )
	deployInternal $@
}

function deployInternal() {
	EXPLODED=""
  	if [ -z $2 ]; then
  		SERVER="$1"
  	fi
  	if [ "$1" = "-x" ]; then
  		EXPLODED="true"
  		SERVER="$2"
  	fi

	if [ -z "${JBOSS4_HOME}" ]; then
		echo "Must specify JBOSS4_HOME"
		return 0;
	fi

	if [ -z "${SERVER}" ]; then
		echo "Must specify server"
		return 0;
	fi

	if [ ! -e ${JBOSS4_HOME}/server/${SERVER} ]; then
		echo "Server ${SERVER} doesn't exist"
		return -1;
	fi

	SERVER_DEPLOY_PATH=${JBOSS4_HOME}/server/${SERVER}/deploy/
	echo "Deploying to: ${SERVER_DEPLOY_PATH}"

	for element in $(seq 0 $((${#FILE_LIST[@]} - 1))); do
		FILE_NAME=${FILE_LIST[$element]##*\/}
		find ${SERVER_DEPLOY_PATH} -name "${FILE_NAME}" -exec rm -rf {} \;
	done

	BUILD_ROOT=`pwd`
	ORIGINAL_BUILD_ROOT=${BUILD_ROOT}

	while [ ! -e ${BUILD_ROOT}/core  ]; do
		BUILD_ROOT=`dirname ${BUILD_ROOT}`
		if [ "${BUILD_ROOT}" == "/" ]; then
			echo "Build root not found from ${ORIGINAL_BUILD_ROOT}"
			return -1;
		fi
	done
	echo "Using build root: ${BUILD_ROOT}"
	

	for element in $(seq 0 $((${#FILE_LIST[@]} - 1))); do
		if [ ! -e ${BUILD_ROOT}/${FILE_LIST[$element]} ]; then
			echo "File not found: ${FILE_LIST[$element]}"
			return -1
		fi
	done

	for element in $(seq 0 $((${#FILE_LIST[@]} - 1))); do
		echo "Copy ${FILE_LIST[$element]} ${SERVER_DEPLOY_PATH}"
		currentFile=`basename ${FILE_LIST[$element]}`
		cp ${BUILD_ROOT}/${FILE_LIST[$element]} ${SERVER_DEPLOY_PATH}
		if [ ! -z ${EXPLODED} ]; then
			if [[ ${currentFile} == *.ear ]]; then
				echo "Unpacking ${currentFile}"
				pushd ${SERVER_DEPLOY_PATH}
				mv ${currentFile} ${currentFile}.tmp
				mkdir ${currentFile}
				mv ${currentFile}.tmp ${currentFile}
				cd ${currentFile}
				jar -xf ${currentFile}.tmp
				cd META-INF
				xsltproc ${SCRIPT_DIR}/rewrite-application-xml.xslt application.xml > application1.xml
				sed -i -r -e 's,<sc/>,<!--\n  ,g' -e 's,<ec/>,\n  -->,g' application1.xml
				mv application1.xml application.xml
				cd ..
				rm ${currentFile}.tmp
				popd
			fi
		fi
	done
}

function go() {
        if [ -z "${SOURCE_ROOT}" ]; then
                echo "ERROR: You must set SOURCE_ROOT to use the go command!" >&2
                return 0
        fi
        cd ${SOURCE_ROOT}/$1
}

function run() {
	if [ -z "$1" ]; then
		echo "No server specified, using default"
		SERVER="default"
	else
		SERVER="$1"
	fi
	${JBOSS4_HOME}/bin/run.sh -c ${SERVER}
}

function st() {
	BUILD_ROOT=`pwd`
	ORIGINAL_BUILD_ROOT=${BUILD_ROOT}

	while [ ! -e ${BUILD_ROOT}/core  ]; do
		BUILD_ROOT=`dirname ${BUILD_ROOT}`
		if [ "${BUILD_ROOT}" == "/" ]; then
			echo "Build root not found from ${ORIGINAL_BUILD_ROOT}"
			return -1;
		fi
	done
	echo "Using build root: ${BUILD_ROOT}"
	mvn -Psystemtest -f tests/systemtest/pom.xml
}

function debug() {
	SERVER="default"
	if [ -z "$1" ]; then
		echo "No server specified, using default"
	else
		SERVER="$1"
	fi
	${JBOSS4_HOME}/bin/debug.sh -c ${SERVER}
}

. ${SCRIPT_DIR}/environment.completions

if [ -z "${SOURCE_ROOT}" ]; then
        echo -en "\E[31;40m\n\nEnvironment variable SOURCE_ROOT is not set.\n\nUpdate your .bashrc!!!\n\n\tEg.\n\texport SOURCE_ROOT=~/Source\n\texport DEFAULT_BASE=${SOURCE_ROOT}/dev\n\n"
        tput sgr0
fi

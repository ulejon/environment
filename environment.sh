#!/bin/bash

# Check environment variables
variables_unset="false"
ENV_VARIABLES=(JAVA_HOME JBOSS4_HOME, JAVA_HOME8 JAVA_HOME7 JAVA_HOME6 SOURCES_ROOT)
for variable in ${ENV_VARIABLES[*]}
do
	value=$(eval "echo \$${variable}")
	if [ -z ${value} ]; then
		echo "Environment variable ${variable} is not set"
		variables_unset="true"
	fi
	#debug....echo "${variable}=${value}"
done
if [ 'true' '==' '${variables_unset}' ]; then
	echo "Not all necessary environment variables set, exiting..."
	return
fi


if [ -z "${JAVA_HOME}" ]; then
	echo "No JAVA_HOME defined, update for example .bashrc"
fi


SCRIPT_DIR=$(cd "$(dirname "$BASH_SOURCE")" && pwd)
if [ -z "`echo $PATH | grep ${SCRIPT_DIR}`" ]; then
	export PATH=${PATH}:${SCRIPT_DIR}
fi


function sbt7() {
	test -f ~/.sbtconfig && . ~/.sbtconfig
	exec ${JAVA_HOME7}/bin/java -Xmx512M ${SBT_OPTS} -jar /usr/local/Cellar/sbt/0.12.3/libexec/sbt-launch.jar "$@"
}

function jboss() {
	if [ -z "$1" ]; then
		SERVER=".."
	else
		SERVER="$1"
	fi
	cd ${JBOSS4_HOME}/server/${SERVER}
}

function setjava() {

	VERSION=$1
	if [ -z "${VERSION}" ]; then
		echo "Must specify version {6,7,8}"
		return
	fi
	PARAM="JAVA_HOME${VERSION}"
	export JAVA_HOME=$(eval "echo \$${PARAM}")
	echo "Set JAVA_HOME to:  ${JAVA_HOME}"
}
function deploytest() {
	FILE_LIST=("tests/ear/target/paysol-*.ear" "core/security/target/paysol-*[^sources].jar"  )
	deployInternal $@
}


function deploy() {
	FILE_LIST=("core/ear/target/paysol-*.ear" "core/security/target/paysol-*[^sources].jar"  )
	deployInternal $@
}

function mi() {
	mvn install "$@"
}

function mci() {
	mvn clean install "$@"
}

function fast() {
	mvn install -Pfast.install "$@"
}

function fastclean() {
	mvn clean install -Pfast.install "$@"
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
		return
	fi

	if [ -z "${SERVER}" ]; then
		echo "No server specified, using default"
		SERVER="default"
	fi

	if [ ! -e ${JBOSS4_HOME}/server/${SERVER} ]; then
		echo "Server ${SERVER} doesn't exist"
		return
	fi

	SERVER_DEPLOY_PATH=${JBOSS4_HOME}/server/${SERVER}/deploy/
	SERVER_CONFIFG=${JBOSS4_HOME}/server/${SERVER}/conf/

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
			return
		fi
	done
	echo "Using build root: ${BUILD_ROOT}"


	for element in $(seq 0 $((${#FILE_LIST[@]} - 1))); do
		if [ ! -e ${BUILD_ROOT}/${FILE_LIST[$element]} ]; then
			echo "File not found: ${FILE_LIST[$element]}"
			return
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

function base() {
	NEW_SOURCE_ROOT=${SOURCES_ROOT}/$1

    if [ -z "${NEW_SOURCE_ROOT}" ]; then
		echo "No path for SOURCE_ROOT specified. Not updating"
		return
	fi
    if [ ! -d "${NEW_SOURCE_ROOT}" ]; then
		echo "Not a valid path [${NEW_SOURCE_ROOT}] for SOURCE_ROOT specified. Not updating"
		return
	fi
        if [ "${NEW_SOURCE_ROOT}" == "${SOURCE_ROOT}" ]; then
		echo "No new path for SOURCE_ROOT specified. Not updating"
		return
	fi
	echo "Setting SOURCE_ROOT to: ${NEW_SOURCE_ROOT}"
	export SOURCE_ROOT=${NEW_SOURCE_ROOT}

	if [ -e "${NEW_SOURCE_ROOT}/.config" ]; then
		echo "Sourcing config"
		source "${NEW_SOURCE_ROOT}/.config"
	fi
	cd ${SOURCE_ROOT}
}

function go() {
        if [ -z "${SOURCE_ROOT}" ]; then
                echo "ERROR: You must set SOURCE_ROOT to use the go command!" >&2
                return
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
			return ;
		fi
	done
	echo "Using build root: ${BUILD_ROOT}"
	pushd ${BUILD_ROOT}
	mvn -Psystemtest -f tests/systemtest/pom.xml
	popd ${BUILD_ROOT}
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

function showjarversion() {
	unzip -q -c $1 META-INF/MANIFEST.MF
}

function clone() {
	cd ${SOURCE_ROOT}
	git clone git@pogit:$1
	cd $(basename $1)
}

function ip() {
	 ifconfig |grep "inet "  | cut -d\  -f2
}

function running () {
	ps -ef | grep $1 | grep -v "grep $1"
}

function tt() {
	texttest.py -c $PWD &
}

function getmissingformdef() {

	DATA_BASE_PATH=$1
	if [ -z "${DATA_BASE_PATH}" ]; then
		echo "Must specify base path for data"
		return
	fi

	FORM_DEF_TO_DOWNLOAD=$2
	if [ -z "${FORM_DEF_TO_DOWNLOAD}" ]; then
		echo "Must specify id of form definition to download"
		return
	fi

	REMOTE_DATA_PATH=$3
	if [ -z "${REMOTE_DATA_PATH}" ]; then
		echo "Must specify remote path to the data folder"
		return
	fi

	while [ ! -e ${DATA_BASE_PATH}  ]; do
		echo "Path ${DATA_BASE_PATH} does not exist"
		return
	done

	scp -r ${REMOTE_DATA_PATH}/forms/${FORM_DEF_TO_DOWNLOAD} ${DATA_BASE_PATH}/forms
	scp -r ${REMOTE_DATA_PATH}/public/forms/${FORM_DEF_TO_DOWNLOAD} ${DATA_BASE_PATH}/public/forms

	echo "All done"
}

function downloadFormdef() {

	REMOTE_DATA_PATH=$1
	if [ -z "${REMOTE_DATA_PATH}" ]; then
		echo "Must specify remote path to the data folder"
		return
	fi

	DATA_BASE_PATH=$2
	if [ -z "${DATA_BASE_PATH}" ]; then
		echo "Must specify base path for data"
		return
	fi

	FORM_DEF_TO_DOWNLOAD=$3
	if [ -z "${FORM_DEF_TO_DOWNLOAD}" ]; then
		echo "Must specify id of form definition to download"
		return
	fi

	while [ ! -e ${DATA_BASE_PATH}  ]; do
		echo "Path ${DATA_BASE_PATH} does not exist"
		return
	done

	scp -r ${REMOTE_DATA_PATH}/forms/${FORM_DEF_TO_DOWNLOAD}/formDef.xlsx ${DATA_BASE_PATH}/${FORM_DEF_TO_DOWNLOAD}/

	echo "All done"
}


function uploadDC() {
	SERVER=$1
  	
  	if [ -z "${SERVER}" ]; then
		echo "No server specified, using dev"
		SERVER="dev"
	fi

    PATH_TO_ZIP=${SOURCES_ROOT}/datacollect-backend/modules/monolith/target/universal
    ZIP_FILE=`find ${PATH_TO_ZIP} -type f -name '*.zip'`
    SERVER_DEPLOY_PATH=${SERVER}:/var/webapps/
	
	PACKAGE_NAME=${ZIP_FILE##*/}
	PACKAGE_NAME=${PACKAGE_NAME%.zip}

	echo "Zip file is: ${ZIP_FILE}"
	echo "Package name is: ${PACKAGE_NAME}"

	while [ ! -e ${ZIP_FILE}  ]; do
		echo "Package (zip) does not exist"
		return
	done

	echo "Uploading ${ZIP_FILE} to: ${SERVER_DEPLOY_PATH}"

	scp ${ZIP_FILE} ${SERVER_DEPLOY_PATH}

	OLD_PACKAGE_NAME=${PACKAGE_NAME}-old
	ssh ${SERVER} "cd /var/webapps && mv ${PACKAGE_NAME} ${OLD_PACKAGE_NAME} && unzip ${PACKAGE_NAME}.zip && cd ${OLD_PACKAGE_NAME} && ../stop-dc.sh && cd .. && cd ${PACKAGE_NAME} && ../start-dc.sh && cd .. && rm ${PACKAGE_NAME}.zip && rm -rf ${OLD_PACKAGE_NAME}"
}


. ${SCRIPT_DIR}/environment.completions


if [ -z "${SOURCES_ROOT}" ]; then
        echo -en "Environment variable SOURCES_ROOT is not set.\n\nUpdate your .bashrc!!!\n\n\tEg.\n\texport SOURCES_ROOT=~/Source\n"
        tput sgr0
fi

KAFKA_SCRIPTS="${SCRIPT_DIR}/kafka.sh"
if [ -f "$KAFKA_SCRIPTS" ]; then
	. ${KAFKA_SCRIPTS}
fi
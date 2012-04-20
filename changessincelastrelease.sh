if [ -z $2 ]; then
	if [ -z $1 ]; then
		REPOSITORY=`pwd`
	elif [ -e $1 ] && [ -d $1 ]; then
		REPOSITORY=$1
	else
		RELEASE_TAG=$1
		REPOSITORY=`pwd`
	fi
else
	REPOSITORY=$1
	RELEASE_TAG=$2
fi

CURR_DIR=`pwd`
cd ${REPOSITORY}
REPOSITORY=`pwd`

git_pwd_is_tracked() {
   [ $(git log -1 --pretty=oneline 2> /dev/null | wc -l) -eq "1" ]
}

if ! git_pwd_is_tracked; then
	echo -e "\033[1;31m'${REPOSITORY}' is not a git repository\033[0m"
	exit 1
fi

if [ -z $RELEASE_TAG ]; then
		echo -e "No release tag supplied, checking log for latest"	
fi

COMMIT_FOR_RELEASE=`git log --grep "\[maven-release-plugin\] prepare release.*${RELEASE_TAG}" --format=oneline | head -1`
COMMIT_HASH=`echo ${COMMIT_FOR_RELEASE} | cut -d " "  -f1`
RELEASE_TAG=`echo ${COMMIT_FOR_RELEASE} | cut -d " " -f4- ` 

if [ -z "${RELEASE_TAG}" ]; then
		echo -e "\033[1;31mNo release tag found\033[0m"
		exit 1	
fi

echo -e "Changes from: \033[1;32m${RELEASE_TAG} (${COMMIT_HASH})\033[0m in repository: \033[1;32m${REPOSITORY}\033[0m"
git log --no-merges --oneline --topo-order --ancestry-path ${COMMIT_HASH}..HEAD | cut -d " "  -f2-

cd ${CURR_DIR}

#!/bin/bash
GIT_LOG_FILE=/tmp/log
LOG_FILE=./progress.log
MAVEN_LOG_FILE=./maven.log

git checkout master
git log --grep "\[maven-release-plugin\] prepare release.*${RELEASE_TAG}.*" --reverse --pretty=format:"%H %ad" --date=short  d60c178b533dad7efb1a42fcd30a35a602c37b7e.. > $GIT_LOG_FILE

SONAR_OPTS="-Dsonar.jdbc.url=jdbc:mysql://10.13.16.121:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true"
SONAR_OPTS="${SONAR_OPTS} -Dsonar.jdbc.driverClassName=com.mysql.jdbc.Driver"
SONAR_OPTS="${SONAR_OPTS} -Dsonar.jdbc.username=sonar"
SONAR_OPTS="${SONAR_OPTS} -Dsonar.jdbc.password=sonar"
SONAR_OPTS="${SONAR_OPTS} -Dsonar.host.url=http://vpogit:8080/sonar"
while read COMMIT_FOR_RELEASE 
do

	COMMIT_HASH=`echo ${COMMIT_FOR_RELEASE} | cut -d " "  -f1`
	COMMIT_DATE=`echo ${COMMIT_FOR_RELEASE} | cut -d " " -f2- ` 
	echo "BUILDING: ${COMMIT_HASH}" >> ${LOG_FILE} 
	git checkout ${COMMIT_HASH}
	mvn clean package -Pfast.install
	mvn sonar:sonar -Dsonar.projectDate=${COMMIT_DATE} ${SONAR_OPTS} >> ${MAVEN_LOG_FILE}
	OUT=$?
	if [ ${OUT} -eq 0 ];then
		echo "OK" >> ${LOG_FILE} 
	else
		exit 1
	fi
done < ${GIT_LOG_FILE}

git checkout master
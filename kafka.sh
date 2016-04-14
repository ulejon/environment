#!/bin/bash

function stopZoo() {
	echo "Stopping zookeeper"
	zkServer stop
}

function startZoo() {
	echo "Starting zookeeper"
	zkServer start
}

function cleanZoo() {
	ZOOKEPER_DATA_DIR=/usr/local/var/run/zookeeper/data/version-2

	echo "Zookeeper data dir is: ${ZOOKEPER_DATA_DIR}"

	if [ ! -d "${ZOOKEPER_DATA_DIR}" ]; then
		echo "Zookeeper data dir does not exist. Not continuing"
		return
	fi

	cd ${ZOOKEPER_DATA_DIR}
	rm -rf *

	echo "all done"
}

function startKafka() {
	echo "Starting kafka"
	kafka-server-start /usr/local/etc/kafka/server.properties
}

function cleanKafkaLogs() {
	KAFKA_LOG_DIR=/usr/local/var/lib/kafka-logs

	echo "Kafka log dir is: ${KAFKA_LOG_DIR}"

	if [ ! -d "${KAFKA_LOG_DIR}" ]; then
		echo "Kafka log dir does not exist. Not continuing"
		return
	fi

	cd ${KAFKA_LOG_DIR}
	rm -rf *

	echo "all done"
}

function cleanKafka() {
	cleanZoo
	cleanKafkaLogs
	echo "Cleaned zookeeper and kafka"
}
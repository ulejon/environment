My Environment scripts
======================

Installation
------------

    curl -s https://raw.github.com/pliljenberg/environment/master/install | bash

This will create ~/tools/environment folder with the scripts. Export some environment variables (from `.profile` or similar) and source the `environment.sh` file
    
	export JAVA_HOME6="/System/Library/Frameworks/JavaVM.framework/Home/"
	export JAVA_HOME7="/Library/Java/JavaVirtualMachines/jdk1.7.0_11.jdk/Contents/Home/"
	export JAVA_HOME=${JAVA_HOME6}
	export JBOSS4_HOME=~/tools/jboss-4.2.1.GA/

	export SOURCES_ROOT=~/Source
	export SOURCE_ROOT=~/Source/pagero
	. ~/tools/environment/environment.sh 


Features
--------
TBD


	`base <name>` 				- set the current source root working environment (tab completes from `SOURCES_ROOT`)
	`go	<name>` 				- change working directory (tab completes from `SOURCE_ROOT` set by `base`)
	`setjava <6|7>`				- set `JAVA_HOME` to `JAVA_HOME6` or `JAVA_HOME7`
	`deploytest <instance>`		- Deploy test ear (defaults to system test JBoss instance, tab complete to show available instances) (looks in curren directory and upwards for files)
	`deploy <instance>`			- Deploy prod ear (defaults to default JBoss instance, tab complete to show available instances) (looks in curren directory and upwards for files)
	`st`						- Run systemtest for current source dir
	`run <instance>`			- Starts JBoss instance`
	`debug <instance>`			- Starts JBoss instance with debug parameters (invokes `debug.sh` instead of `run.sh`, so configure JBoss accordingly)
	`jboss <instance>`			- Change dir to `JBOSS4_HOME` or `JBOSS4_HOME/server/instance` if specified
	`mi <params>`				- Invokes `mvn clean install <params>` in the currect directory
	`mci <params>`				- Invokes `mvn install <params>` in the current directory
	`fast <params>`				- Invokes `mvn install -Pfast.install <params>` in the current directory (skips test compile and tests)
	`fastclean <params>`		- Invokes `mvn clean install -Pfast.install <params>` in the current directory (skips test compile and tests)
	
	`allstat`					- Show git statistics for all repositories under `SOURCE_ROOT`
	`allstash`					- Show git stashes for all repositories under `SOURCE_ROOT`
	`changessincelastrelease`	- Show changes since last release for current directory
	`setversion <version>`		- Updates `pom.xml` versions to `version` for current directory (and children)
	`git-wtf`					- Shows (extensive) git repository status compared with remote (i.e. need to push/pull branches and so on)
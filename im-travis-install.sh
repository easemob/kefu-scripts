#!/bin/bash

# Note: This file is not allowed to be modified locally.
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export PATH=$JAVA_HOME/bin:$PATH
java -Xmx32m -version
javac -J-Xmx32m -version
alias mvn='mvn -B -T 4'


MAVEN_OPTIONS="-Pci -DskipTests=true -Dmaven.test.redirectTestOutputToFile=false -Dsurefire.useFile=false -e -V"
SONAR_EXCLUSION_OPTION="-Dsonar.exclusions=src/main/java/com/easemob/thrift/**/*"
SONAR_HOST_OPTIONS="-Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_LOGIN -Dsonar.password=$SONAR_PASSWD"

SONAR_GITHUB_OPTIONS="-Dsonar.github.pullRequest=$TRAVIS_PULL_REQUEST -Dsonar.github.repository=$TRAVIS_REPO_SLUG -Dsonar.github.login=$SONAR_GITHUB_LOGIN -Dsonar.github.oauth=$SONAR_GITHUB_OAUTH"

SONAR_EXTRA_OPTIONS="-Dsonar.verbose=true"
if [ "$TRAVIS_PULL_REQUEST" != "false" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    echo 'Internal pull request: trigger QA and analysis'

    mvn clean package sonar:sonar  \
        $MAVEN_OPTIONS \
        $SONAR_EXCLUSION_OPTION \
		$SONAR_HOST_OPTIONS \
		$SONAR_GITHUB_OPTIONS \
	    -Dsonar.analysis.mode=preview \
		$SONAR_EXTRA_OPTIONS \
	    -s ./travis/.travis_settings.xml  $@ | grep -vE '^\[info\]|\[main\]|MB/s|^Collecting|Receiving objects|Resolving deltas:|remote: Compressing objects:|Downloading|Extracting|Pushing|[0-9]+ KB'


    MVN_STATUS=${PIPESTATUS[0]}

    if [ $MVN_STATUS != 0 ]
    then
        exit $MVN_STATUS
    fi
elif [ "TRAVIS_TAG" != "false" ] && [ "TRAVIS_TAG" != "" ]; then
	echo "######## Building Release ${TRAVIS_TAG}"
	
    docker login  -u="$DOCKER_USER" -p="$DOCKER_PASSWD" $DOCKER_REGISTRY
    echo "running maven build with direct push"
    mvn clean test package sonar:sonar deploy -Pdocker -DpushImage -U \
		$MAVEN_OPTIONS \
		$SONAR_EXCLUSION_OPTION \
		$SONAR_HOST_OPTIONS \
		$SONAR_EXTRA_OPTIONS \
		-s ./travis/.travis_settings.xml  $@ | grep -vE '^\[info\]|\[main\]|MB/s|^Collecting|Receiving objects|Resolving deltas:|remote: Compressing objects:|Downloading|Extracting|Pushing|[0-9]+ KB'

    MVN_STATUS=${PIPESTATUS[0]}

    if [ $MVN_STATUS != 0 ]
    then
        exit $MVN_STATUS
    fi
	
else
    echo "running maven build with direct push"
    mvn clean test package sonar:sonar deploy  -U \
		$MAVEN_OPTIONS \
		$SONAR_EXCLUSION_OPTION \
		$SONAR_HOST_OPTIONS \
		$SONAR_EXTRA_OPTIONS \
		-s ./travis/.travis_settings.xml  $@ | grep -vE '^\[info\]|\[main\]|MB/s|^Collecting|Receiving objects|Resolving deltas:|remote: Compressing objects:|Downloading|Extracting|Pushing|[0-9]+ KB'

    MVN_STATUS=${PIPESTATUS[0]}

    if [ $MVN_STATUS != 0 ]
    then
        exit $MVN_STATUS
    fi
fi

# For release
#mvn clean deploy -DskipTests -s .travis_settings.xml -Dsettings.security=.travis_settings-security.xml | grep -v "maven\|WARNING\|Unpacking\|Uploaded"


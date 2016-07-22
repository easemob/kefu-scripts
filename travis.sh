#!/bin/bash

#set -euo pipefail


export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export PATH=$JAVA_HOME/bin:$PATH
java -Xmx32m -version
javac -J-Xmx32m -version
export SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL="false"
export SPRING_JPA_PROPERTIES_HIBERNATE_SHOW_SQL="false"
export LOGGING_LEVEL_ROOT="WARN"
alias mvn='mvn -B -T 4'
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    if [ -n "$SONAR_GITHUB_OAUTH" ]; then
        echo "Start pullrequest analysis"
        mvn clean test install sonar:sonar -Pci \
            -Dsonar.analysis.mode=preview \
            -Dsonar.verbose=true \
            -Dsonar.github.pullRequest=$TRAVIS_PULL_REQUEST \
            -Dsonar.github.repository=$TRAVIS_REPO_SLUG \
            -Dsonar.github.login=$SONAR_GITHUB_LOGIN \
            -Dsonar.github.oauth=$SONAR_GITHUB_OAUTH \
            -Dsonar.host.url=$SONAR_HOST_URL \
            -Dsonar.login=$SONAR_LOGIN \
            -Dsonar.password=$SONAR_PASSWD \
            -s settings.xml -Dsettings.security=settings-security.xml $@
    fi
else
    docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" docker-registry.easemob.com
    mvn clean test install sonar:sonar package deploy -U \
        -Pdocker -Pci \
        -s settings.xml \
        -DpushImage \
        -Dsonar.host.url=$SONAR_HOST_URL \
        -Dsonar.login=$SONAR_LOGIN \
        -Dsonar.password=$SONAR_PASSWD \
        -Dsettings.security=settings-security.xml $@ | grep -vE '^\[info\]|\[main\]|MB/s|^Collecting|Receiving objects|Resolving deltas:|remote: Compressing objects:|Downloading|Extracting|Pushing|[0-9]+ KB'

    MVN_STATUS=${PIPESTATUS[0]}

    if [ $MVN_STATUS != 0 ]
    then
        exit $MVN_STATUS
    fi
fi


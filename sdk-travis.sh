#!/bin/bash

#set -euo pipefail

echo $1
echo $2

echo "begin..."

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo "start pr analysis"
    if [ -n "$SONAR_GITHUB_OAUTH" ]; then
        echo "Start pullrequest analysis"
        ./gradlew -PisTravis=true $1 $2 -Dsonar.host.url=$SONAR_URL\
            -Dsonar.login=$SONAR_USER\
	    -Dsonar.password=$SONAR_PASSWORD\
            -Dsonar.github.pullRequest=$TRAVIS_PULL_REQUES \
            -Dsonar.github.repository=$TRAVIS_REPO_SLUG\
            -Dsonar.github.login=$SONAR_GITHUB_LOGIN\
            -Dsonar.github.oauth=$SONAR_GITHUB_OAUTH\
            -Dbuildtime.output.log=true\
	    --info --stacktrace
        
        MVN_STATUS=${PIPESTATUS[0]}

        if [ $MVN_STATUS != 0 ]
        then
            exit $MVN_STATUS
        fi
    fi
else
     echo "Start full analysis"
     echo $TASK1
     echo $TASK2
     ./gradlew -PisTravis=true $1 $2 -Dsonar.host.url=$SONAR_URL\
          -Dsonar.login=$SONAR_USER\
	  -Dsonar.password=$SONAR_PASSWORD\
          -Dsonar.verbose=true\ 
          -Dbuildtime.output.log=true\
	  --info --stacktrace

    MVN_STATUS=${PIPESTATUS[0]}

    if [ $MVN_STATUS != 0 ]
    then
        exit $MVN_STATUS
    fi
fi
echo "end ..."

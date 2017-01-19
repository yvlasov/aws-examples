#!/bin/bash
df -h 

docker rm $(docker ps -a --filter "status=exited" --no-trunc -aq 2> /dev/null ) 2> /dev/null

docker rmi $(docker images -q -f "dangling=true" --no-trunc 2> /dev/null ) 2> /dev/null

DELETE_MIN_TIME_GAP=$[ 3600 * 8 ];
DELETE_MAX_TIME_GAP=$[ 3600 * 24 * 3 ];
CUR_DATE=$(date +%s)
docker images --no-trunc -aq 2> /dev/null | \
while read line
do
    CREATE_TIMESTAMP=0
    echo "Inspecting image: $line"
    CREATE_TIMESTAMP=`date --date="$( docker inspect -f '{{ .Created }}' $line 2> /dev/null )" +%s`
    if [ $CREATE_TIMESTAMP -le $[ $CUR_DATE - $DELETE_MIN_TIME_GAP ] ] && [ $CREATE_TIMESTAMP -gt $[ $CUR_DATE - $DELETE_MAX_TIME_GAP ] ]; then
      echo "Deleting image: $line"
      docker rmi -f $line 2> /dev/null
    fi
done 

df -h

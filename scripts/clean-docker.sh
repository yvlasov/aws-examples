#!/bin/bash
df -h 

if [ x$( docker ps -a --filter "status=exited" --no-trunc -aq 2> /dev/null | wc -l ) != "x0" ]; then
	docker rm $(docker ps -a --filter "status=exited" --no-trunc -aq 2> /dev/null ) 2> /dev/null
fi

if [ x$( docker images -q -f "dangling=true" --no-trunc 2> /dev/null | wc -l ) != "x0" ]; then
	docker rmi $(docker images -q -f "dangling=true" --no-trunc 2> /dev/null ) 2> /dev/null
fi

CUR_DATE=$(date +%s)
DELETE_MIN_TIME_GAP=$[ $CUR_DATE - ( 3600 * 24 ) ];
DELETE_MAX_TIME_GAP=$[ $CUR_DATE - ( 3600 * 24 * 5 ) ];

#WHILE LOOP sh compatible
docker images --no-trunc -aq 2> /dev/null | while read line
do
  if [ x$line != "x" ]; then  
    CREATE_TIMESTAMP=0
    #echo "Inspecting image: $line"
    CREATE_TIMESTAMP=`date --date="$( docker inspect -f '{{ .Created }}' $line 2> /dev/null )" +%s`
    if [ x$CREATE_TIMESTAMP != "x" ] && [ $CREATE_TIMESTAMP -le $DELETE_MIN_TIME_GAP ] && [ $CREATE_TIMESTAMP -gt $DELETE_MAX_TIME_GAP ]; then
      echo "Deleting image: $line"
      docker rmi -f $line 
    fi
  fi
done

df -h

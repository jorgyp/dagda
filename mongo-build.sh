#!/bin/bash

#build and initialize dagda scanner 
docker rm -f dagda
docker rm -f vulndb
docker-compose build
docker-compose up -d
sleep 10

docker exec dagda /bin/sh -c "python /opt/app/dagda.py vuln --init"
dbState=$(docker exec dagda /bin/sh -c "python /opt/app/dagda.py vuln --init_status" |  jq '.status' | sed 's/\"//g')
	      
    while [[ $dbState != 'Updated' ]]; do
        sleep 3
        echo "vulnerability db download in progress… ${dbState}"
        dbState=$(docker exec dagda /bin/sh -c "python /opt/app/dagda.py vuln --init_status" |  jq '.status' | sed 's/\"//g')
    done

    echo  "vulnerability database update complete"


docker build -f Dockerfile-mongo -t syagolnikov/mongo:latest .
docker push syagolnikov/mongo:latest
docker rm -f dagda
docker rm -f vulndb
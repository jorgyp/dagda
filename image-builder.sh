#!/bin/bash
#bash image-builder.sh syagolnikov

if [[ -z $1 ]]; then 
    echo 'docker repo/folder name missing, exit...'
    exit 1
else 
    FOLDER=$1
fi

docker rm -f dagda
docker rm -f vulndb

docker build -f Dockerfile -t ${FOLDER}/dagda:latest .
docker push ${FOLDER}/dagda:latest

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

docker build -f Dockerfile-mongo -t ${FOLDER}/mongo:latest .
docker push ${FOLDER}/mongo:latest
docker rm -f dagda
docker rm -f vulndb
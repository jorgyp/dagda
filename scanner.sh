#!/bin/bash
# source: https://github.com/eliasgranderubio/dagda.git

#scanner.sh <image_name>
if [[ -z $1 ]]; then 
	imageName='jboss/wildfly:8.2.0.Final'
else
	imageName=$1
fi
echo "$imageName"

#build and initialize dagda scanner 
docker rm -f dagda
docker rm -f vulndb
docker-compose build
docker-compose up -d
sleep 10

# docker exec dagda /bin/sh -c "python /opt/app/dagda.py vuln --init"
# dbState=$(docker exec dagda /bin/sh -c "python /opt/app/dagda.py vuln --init_status" |  jq '.status' | sed 's/\"//g')
	      
    # while [[ $dbState != 'Updated' ]]; do
    #     sleep 3
    #     echo "vulnerability db download in progress… ${dbState}"
    #     dbState=$(docker exec dagda /bin/sh -c "python /opt/app/dagda.py vuln --init_status" |  jq '.status' | sed 's/\"//g')
    # done

    # echo  "vulnerability database update complete"

#perform image scan
docker pull $imageName

imageId=$(docker exec dagda /bin/sh -c "python /opt/app/dagda.py check -i ${imageName}" | jq .id)
echo "scan started for imageId: ${imageId}"

dbScan=`docker exec dagda /bin/sh -c "python /opt/app/dagda.py history ${imageName} --id ${imageId}" | jq -c '.[].status' | sed 's/\"//g'`

while [[ $dbScan != 'Completed' ]]; do
	sleep 3
	echo "image ${imageId} inspection in progress… $dbScan"
	dbScan=`docker exec dagda /bin/sh -c "python /opt/app/dagda.py history ${imageName} --id ${imageId}" | jq -c '.[].status' | sed 's/\"//g'`

	if [[ $dbScan != 'Completed' ]] && [[ $dbScan != 'Analyzing' ]]; then
		echo 'Unknown image, please ensure image name exists'
		exit 1
	fi
done

echo "vulnerability scan completed"

#display found vulnerabilities 
totalVulnerabilies=`docker exec dagda /bin/sh -c "python /opt/app/dagda.py history ${imageName} --id ${imageId}" | jq '.[].static_analysis.os_packages.vuln_os_packages'`

if [[ $totalVulnerabilies =~ ^[0-9]+$ ]] && [[ $totalVulnerabilies -ge 1 ]] ; then
      echo "found ${totalVulnerabilies} vulnerabilities. Please try using different image and review items in Dagda scan: ${imageId} "
      exit 1
fi

echo "no vulnerabilities exist"

#running malware test
docker rm -f test 
docker run -td --name test $imageName /bin/sh

containerId=$(docker ps --filter "name=test" --format "{{.ID}}")
docker exec dagda /bin/sh -c "python /opt/app/dagda.py monitor ${containerId} --start"

#simulate attack
docker exec test /bin/sh -c 'nc -vv -z 127.0.0.1 80'

#monitor container for 60 seconds 
sleep 60
monitoringResults=`docker exec dagda /bin/sh -c "python /opt/app/dagda.py monitor ${containerId} --stop"`
echo ${monitoringResults}
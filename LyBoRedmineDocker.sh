#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'          # Black
Red='\033[0;31m'            # Red
Green='\033[0;32m'          # Green
ForegroundBlue='\033[0;34m' #Foreground Blue
White='\033[0;37m'          # White

function currentDateTime () {
    if hash gdate &> /dev/null ; then
        printf "$(gdate +'%Y-%m-%d %T.%3N') ... "
    else
        printf "$(date +'%Y-%m-%d %T') ... "
    fi
}

RedmineImageName='sameersbn/redmine:4.1.1-8 '
PostgresqlImageName='sameersbn/postgresql:9.6-4 '

#Open Docker, only if is not running
if (! docker stats --no-stream &> /dev/null ); then
    currentDateTime
    echo "S00_To Boot Docker ..."
    startTimer=$(date +%s)
    # On Mac OS this would be the terminal command to launch Docker
    open /Applications/Docker.app
    #Wait until Docker daemon is running and has completed initialisation
    while (! docker stats --no-stream &> /dev/null ); do
        # Docker takes a few seconds to initialize
        let elapsedTime=$(date +%s)-startTimer
        printf "..$elapsedTime"
        sleep 5
    done
    printf ".."
    echo -e "${Green}OK.${Color_Off}"
else
    currentDateTime
    echo -e "${Green}S01_Docker is already running...${Color_Off}"
fi

currentDateTime
echo "S02_Create Symbol Link..."
FILE=/tmp/redmine
if [ -d "$FILE" ]; then
    currentDateTime
    echo -e "\t$FILE exists."
else
    currentDateTime
    printf "\tredmine link ..."
    ln -s ~/Redmine_Docker/data_from_tmp_root/redmine $FILE
    echo -e "${Green}OK.${Color_Off}"
fi

FILE=/tmp/postgresql
if [ -d "$FILE" ]; then
    currentDateTime
    echo -e "\t$FILE exists."
else
    currentDateTime
    printf "\tpostgresql link ..."
    ln -s ~/Redmine_Docker/data_from_tmp_root/postgresql $FILE
    echo -e "${Green}OK.${Color_Off}"
fi

currentDateTime
echo "S03_Boot Postgresql..."
result=$( docker images -q $PostgresqlImageName )
if [[ -n "$result" ]]; then
    if [ "$(docker ps -q --filter ancestor=$PostgresqlImageName --filter status=exited)" ]; then
        currentDateTime
        printf "\tdocker restart ..."
        docker restart postgresql-redmine
    else
        currentDateTime
        echo -e "\tpostgresql-redmine is already running."
    fi
else
    currentDateTime
    printf "\tdocker run ..."
    docker run --name=postgresql-redmine -d --env='DB_NAME=redmine_production' --env='DB_USER=redmine' --env='DB_PASS=password' --volume=/tmp/postgresql:/var/lib/postgresql $PostgresqlImageName
fi

currentDateTime
echo "S04_Boot Redmine..."
result=$( docker images -q $RedmineImageName )
if [[ -n "$result" ]]; then
    if [ "$(docker ps -q --filter ancestor=$RedmineImageName --filter status=exited)" ]; then
        currentDateTime
        printf "\tdocker restart ..."
        docker restart redmine
    else
        currentDateTime
        echo -e "\tredmine is already running."
    fi
else
    currentDateTime
    printf "\tdocker run ..."
    docker run --name=redmine -d --link=postgresql-redmine:postgresql --publish=10083:80  --env='REDMINE_PORT=10083' --env='NGINX_MAX_UPLOAD_SIZE=200m'  --volume=/tmp/redmine:/home/redmine/data $RedmineImageName
fi

echo -e "\nRedmine is Ready.Please access: ${ForegroundBlue}http://localhost:10083${Color_Off}"

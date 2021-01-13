#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

function currentDateTime () {
    if hash gdate &> /dev/null ; then
        printf "$(gdate +'%Y-%m-%d %T.%3N') ... "
    else
        printf "$(date +'%Y-%m-%d %T') ... "
    fi
}

#Open Docker, only if is not running
if (! docker stats --no-stream ); then
    currentDateTime
    echo "S00_To Boot Docker ..."
    # On Mac OS this would be the terminal command to launch Docker
    open /Applications/Docker.app
    #Wait until Docker daemon is running and has completed initialisation
    while (! docker stats --no-stream ); do
        # Docker takes a few seconds to initialize
        printf "."
        sleep 5
    done
    echo -e "${Green}OK.${Color_Off}"
else
    currentDateTime
    echo -e "${Green}S01_Docker is already running...${Color_Off}"
fi

currentDateTime
echo "S02_Create Symbol Link..."
FILE=/tmp/redmine
if [ -d "$FILE" ]; then
    echo "$FILE exists."
else
    currentDateTime
    printf "redmine link ..."
    ln -s ~/Redmine_Docker/data_from_tmp_root/redmine $FILE
    echo -e "${Green}OK.${Color_Off}"
fi

FILE=/tmp/postgresql
if [ -d "$FILE" ]; then
    echo "$FILE exists."
else
    currentDateTime
    printf "postgresql link ..."
    ln -s ~/Redmine_Docker/data_from_tmp_root/postgresql $FILE
    echo -e "${Green}OK.${Color_Off}"
fi

currentDateTime
echo "S03_Boot Postgresql..."
if [ "$(docker ps -a | grep postgresql-redmine)" ]; then
    currentDateTime
    printf "docker restart ..."
    docker restart postgresql-redmine
else
    currentDateTime
    printf "docker run ..."
    docker run --name=postgresql-redmine -d --env='DB_NAME=redmine_production' --env='DB_USER=redmine' --env='DB_PASS=password' --volume=/tmp/postgresql:/var/lib/postgresql sameersbn/postgresql:9.6-4
fi

currentDateTime
echo "S04_Boot Redmine..."
if [ "$(docker ps -a | grep redmine)" ]; then
    currentDateTime
    printf "docker restart ..."
    docker restart redmine
else
    currentDateTime
    printf "docker run ..."
    docker run --name=redmine -d --link=postgresql-redmine:postgresql --publish=10083:80  --env='REDMINE_PORT=10083' --env='NGINX_MAX_UPLOAD_SIZE=200m'  --volume=/tmp/redmine:/home/redmine/data sameersbn/redmine:4.1.1-8
fi


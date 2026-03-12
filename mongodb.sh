#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then 
    echo -e "$R you should run this script as root user $N"
    exit 1
fi

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2....$R Failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2....$G Success $N" | tee -a $LOG_FILE
    fi
} 

mkdir -p LOG_FOLDER

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
validate $? "copying mongo repo file"

dnf install mongodb-org -y &>> $LOG_FILE
validate $? "Installing mongodb"

systemctl enable mongodb &>> $LOG_FILE
validate $? "Enabling mongodb"

systemctl start mongodb &>> $LOG_FILE
validate $? "Starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> LOG_FILE
validate $? "Allowing remote connections to mongodb"

systemctl restart mongodb &>> $LOG_FILE
validate $? "Restarting mongodb"


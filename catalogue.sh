#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="var/log/shell-roboshop"
LOG_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.devzone.fun"

if [ $USERID -ne 0 ]; then
    echo -e "$R you should run this script as root user $N"
    exit 1
fi
mkdir -p $LOGS_FOLDER

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2....$R Failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2....$G Success $N" | tee -a $LOG_FILE
    fi
}


dnf module disable nodejs -y &>> $LOG_FILE
validate $? "Disabling nodejs module"

dnf module enable nodejs:20 -y &>> $LOG_FILE
validate $? "Enabling nodejs 20"

dnf install nodejs -y &>> $LOG_FILE
validate $? "Installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    validate $? "creatring roboshop user"
else
    echo -e "Roboshop user already exits ....$G Skipping $N" | tee -a $LOG_FILE
fi

mkdir -p /app &>> $LOG_FILE
validate $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
validate $? "downloading catalogue zip code"

cd /app &>> $LOG_FILE
validate $? "Moving to app directory"

rm -rf /app/*
validate $? "cleaning old content"

unzip /tmp/catalogue.zip &>> $LOG_FILE
validate $? "extracting catalogue code"

npm install &>> $LOG_FILE
validate $? "Installing nodejs dependencies"

cp SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
validate $? "copying catalogue systemd service file"

systemctl daemon-reload

systemctl enable catalogue &>> $LOG_FILE
validate $? "Enabling catalogue service"

systemctl start catalogue &>> $LOG_FILE
validate $? "Starting catalogue service"

cp SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE

dnf install mongodb-mongosh -y &>> $LOG_FILE
validate $? "Installing mongosh"

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"





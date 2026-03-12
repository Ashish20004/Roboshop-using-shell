#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOOG_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MOGODB_HOST="mongodb.devzone.fun"

if [ $USERID -ne 0 ]; then
    echo -e "$R you should run this script as root user $N" | tee -a $LOG_FILE
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
validate $? "Disabling nodejs repo"

dnf module enable nodejs:20 -y &>> $LOG_FILE
validate $? "Enabbling nodejs repo"

dnf install nodejs -y &>> $LOG_FILE
validate $? "Installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop Application user" roboshop &>> $LOG_FILE
    validate $? "creating roboshop user"
else
    echo -e "$Y roboshop user already exits $N" 
fi

mkdir -p /app
validate $? "Creating application directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
validate $? "Downloading cart application code"

cd /app
validate $? "Moving to application directory"

unzip /tmp/cart.zip
validate $? " Extracting cart application code"

npm install
validate $? "Installing nodejs dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
validate $? "Copying cart systemd service file"

systemctl daemon-reload
systemctl enable cart &>> $LOG_FILE
systemctl start cart $







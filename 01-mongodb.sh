#!/bin/bash
LOGS_FOLDER="/var/log/roboshop"
mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER 
LOGS_FILE="$LOGS_FOLDER/$0.log"

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m]"
if [ $USERID -ne 0 ]; then
   echo -e "$R Please run the script as root user $N" | tee -a $LOGS_FILE
   exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 $R is failure $N" | tee -a $LOGS_FILE
        exit 1
    else
    echo -e "$2 is $G success $N" | tee -a $LOGS_FILE
}

cp mongo.repo /etc/yum.repos.d/mongo.repo 
validate $? "adding mongo repo"

dnf install mongodb-org -y &>> $LOGS_FILE
validate $? "installing mongodb"

systemctl enable --now mongod &>> $LOGS_FILE
validate $? "starting and enabling mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "allowing remote connections to mongodb"


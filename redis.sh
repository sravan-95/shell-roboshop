#!/bin/bash

LOGS_FOLDER="var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

USERID=$(id -u)
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
 R="\e[31m"
 G="\e[32m"
 Y="\e[33m"
 N="\e[0m"

 if [ $USERID -ne 0 ]; then
    echo -e "$timestamp $R please run the script with root access $N" | tee -a $LOGS_FILE
    exit 1 
 fi

 validate() {
     if [ $1 -ne 0 ]; then
        echo -e "$timestamp $2... $R failure $N" | tee -a $LOGS_FILE
        exit 1
     else 
        echo -e "$timestamp $2...$G success $N" | tee -a $LOGS_FILE
    fi
 }

    dnf module disable redis -y
    dnf module enable redis:7 -y
    dnf install redis -y 
    validate $? "installing redis:7"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected mode/ c protected mode no' /etc/redis.conf
validate $? "allowing remote connections"

systemctl enable redis 
systemctl start redis 
validate $? "started redis"


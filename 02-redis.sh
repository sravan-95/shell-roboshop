#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
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
    fi
}

dnf module disable redis -y &>> $LOGS_FILE
validate $? "disable redis7"

dnf module enable redis -y &>> $LOGS_FILE
validate $? "enable redis"

dnf install redis -y &>> $LOGS_FILE
validate $? "Installing Redis"

systemctl enable redis &>> $LOGS_FILE
validate $? "enable redis"

systemctl start redis &>> $LOGS_FILE
validate $? "Started Redis"
 
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "Allowing remote connections"


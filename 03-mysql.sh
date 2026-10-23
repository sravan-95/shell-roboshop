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
    fi
}

dnf install mysql-server -y &>> $LOGS_FILE
validate $? "Installing mysql-server"

systemctl enable mysqld &>> $LOGS_FILE
systemctl start mysqld  &>> $LOGS_FILE
validate $? "Enable and start MySQL server"

mysql_secure_installation --set-root-pass RoboShop@1
validate $? "Setting up root password"
#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07487282QSHCXKXC175U" # replace with your zone ID
DOMAIN_NAME="daws90.fun" # replace with your domain name
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $# -lt 2 ]; then
echo -e "$R ERROR $N provide atleast 2 arguments"
echo "USAGE: $0 [create/delete] [instance1] [instance2]..."
exit 1
fi

ACTION=$1
shift 
if [ $ACTION != "create" ] && [ $ACTION != "delete"]; then
echo -e "$R ERROR:: first argument should be either create or delete $N"
ech o "USAGE: $0 [create/delete] [instance1] [instance2]..."
exit 1
fi
 
get_instance_id(){
    name=$1
    aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text
} 
for instance in $@
do
    INSTANCE_ID=$(get_instance_id $instance)
    if [ $ACTION == "create" ]; then
        if [ $INSTANCE_ID == none ]; then
        echo "launching instance: roboshop-$instance"
        INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-0220d79f3f480ecf5 \
        --instance-type t3.micro \
        --security-groups "roboshop-common" "roboshop-$instance" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)
        echo "launched instance: $INSTANCE_ID"

              if [ $instance == "frontend" ]; then
              IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                 --query 'Reservations[*].Instances[*].PublicIpAddress' \
                 --output text)
              R53_RECORD="$DOMAIN_NAME"
              else
              IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
              --query 'Reservations[*].Instances[*].PrivateIpAddress' \
              --output text)
              R53_RECORD="$instance.$DOMAIN_NAME"
              fi

              aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
        {
            "Comment": "Update A record to new IP",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": "'$R53_RECORD'",
                        "Type": "A",
                        "TTL": 1,
                        "ResourceRecords": [
                            {
                                "Value": "'$IP'"
                            }
                        ]
                    }
                }
            ]
        }
    '
        echo "updated route53 record for: $instance"
        else 
        echo "roboshop-$instance already running: $INSTANCE_ID"
        fi
    else 
        if [ $INSTANCE_ID == "none" ]; then
        echo "$instance already deleted"
        else 
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID
        echo "terminating instance: $instance"
        fi
    fi    
done
   
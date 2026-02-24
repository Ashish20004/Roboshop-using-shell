#!/bin/bash

SG_ID="sg-0d5d4fedeb7568090"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z06798631LYJMO4Z0P7UU"
DOMAIN_NAME="devzone.fun"

for instance in $@
do 
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text )
    
    if [ $instance == "frontend" ]; then
         IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[].Instances[].publicIpAddress" \
            --output text )
        RECORD_NAME="$DOMAIN_NAME"
    else
         IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[].Instances[].privateIpAddress" \
            --output text
             )
         RECORD_NAME="$instance.$DOMAIN_NAME"
    fi
    echo "IP: $IP"
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
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
}'

    echo "records updated for $instance"
done
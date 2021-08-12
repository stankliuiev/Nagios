#!/bin/bash
#AWS AutoScaling monitoring script
#Stanislav Kliuiev, 2021-08-12
#https://nksupport.com

#get balancer arn
balancer_arn=$(/usr/local/bin/aws elbv2 describe-load-balancers --names "yourbalancername" |  grep LoadBalancerArn | awk '{print $2}'| tr -d '",')
#get balancer tg
balancer_tg=$(/usr/local/bin/aws elbv2 describe-target-groups --load-balancer-arn "$balancer_arn" | grep TargetGroupName | tr -d '",' | awk '{print $2}')
#get autoscaling group name
autoscalegroupname=$(/usr/local/bin/aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? TargetGroupARNs [? contains(@, '$balancer_arn')]].AutoScalingGroupName" |tr -d '"' |head -2 |tail -1)
#get a number of max instances that can be spawned
maxinstances=$(/usr/local/bin/aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $autoscalegroupname --query "AutoScalingGroups[*].MaxSize" |head -2 |tail -1)
#the number of actually spawned instances at the moment
instancesrunning=$(/usr/local/bin/aws ec2 describe-instances | grep autoscalegroupname | wc -l)
#warning limit is set to 80%, but you can set it as you wish
warning_limit=$(bc <<<"$maxinstances*80/100")

#for test purposes
#instancesrunning=$(echo 3)

if 
        [ "$instancesrunning" -lt "$warning_limit" ]
then
    echo "Spawned instances quantity is $instancesrunning, status is OK!"
    exit 0
elif
       [[ "$instancesrunning" -lt "$maxinstances" && "$instancesrunning" -ge "$warning_limit" ]]
then
    echo "WARNING! Spawned instances quantity is $instancesrunning, status is NOT ok!!! Need attention!"
    exit 1
elif
       [[ "$instancesrunning" -ge "$warning_limit" && "$instancesrunning" -ge "$maxinstances" ]]
then
    echo "CRITICAL! Spawned instances quantity is $instancesrunning, status is NOT ok!!! Need attention urgently!"
    exit 2
fi

#!/bin/bash
#AWS AutoScaling monitoring script
#Stanislav Kliuiev, 2021-08-12
#https://nksupport.com

balancer_arn=$(/usr/local/bin/aws elbv2 describe-load-balancers --names "weboffertorocom-prod-new-lb" |  grep LoadBalancerArn | awk '{print $2}'| tr -d '",')
balancer_tg=$(/usr/local/bin/aws elbv2 describe-target-groups --load-balancer-arn "$balancer_arn" | grep TargetGroupName | tr -d '",' | awk '{print $2}')
autoscalegroupname=$(/usr/local/bin/aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? TargetGroupARNs [? contains(@, '$balancer_arn')]].AutoScalingGroupName" |tr -d '"' |head -2 |tail -1)
maxinstances=$(/usr/local/bin/aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $autoscalegroupname --query "AutoScalingGroups[*].MaxSize" |head -2 |tail -1)
instancesrunning=$(/usr/local/bin/aws ec2 describe-instances | grep CodeDeploy_offertoro-deployment | wc -l)
warning_limit=$(echo "$(( $maxinstances / 10 * 8 ))")

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

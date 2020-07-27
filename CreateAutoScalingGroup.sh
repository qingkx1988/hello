#! /bin/sh
configName="$1"
ASGName="$2"
aws autoscaling create-launch-configuration --image-id ami-08f3d892de259504d --instance-type t2.micro --key-name myKey1 --security-groups sg-84bfc2bd --user-data file:///home/ec2-user/as-bootstrap.sh --launch-configuration-name $configName
aws autoscaling create-auto-scaling-group --auto-scaling-group-name $ASGName --launch-configuration-name $configName --load-balancer-names myCLB1 --max-size 4 --min-size 1 --vpc-zone-identifier subnet-dad7b897,subnet-697ea636,subnet-deeb34b8
upARN=`aws autoscaling put-scaling-policy --policy-name lab-scale-up-policy --auto-scaling-group-name $ASGName --scaling-adjustment 1 --adjustment-type ChangeInCapacity --cooldown 300 --query 'PolicyARN' --output text`
aws cloudwatch put-metric-alarm --alarm-name Step-Scaling-AlarmHigh-AddCapacity \
  --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average \
  --period 120 --evaluation-periods 2 --threshold 60 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASGName" \
  --alarm-actions $upARN
downARN=`aws autoscaling put-scaling-policy --policy-name lab-scale-down-policy --auto-scaling-group-name $ASGName --scaling-adjustment -1 --adjustment-type ChangeInCapacity --cooldown 300 --query 'PolicyARN' --output text`
aws cloudwatch put-metric-alarm --alarm-name Step-Scaling-AlarmLow-RemoveCapacity \
  --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average \
  --period 120 --evaluation-periods 2 --threshold 40 \
  --comparison-operator LessThanOrEqualToThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASGName" \
  --alarm-actions $downARN

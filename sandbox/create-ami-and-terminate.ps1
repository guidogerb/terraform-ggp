# Define variables
$InstanceId = "i-0a9168def2554cdb6"
$AmiName = "MyDeepseekBackup-2025-02-01"

# Step 1: Create AMI from the instance
# $AmiId = aws ec2 create-image --instance-id $InstanceId --name $AmiName --no-reboot --query "ImageId" --output text
# Write-Output "AMI Creation Started: $AmiId"

# Step 2: Wait for AMI to become available
Write-Output "Waiting for AMI ($AmiId) to become available..."
aws ec2 wait image-available --image-ids $AmiId
Write-Output "AMI ($AmiId) is now available."

# Step 3: Terminate the original EC2 instance
Write-Output "Terminating instance: $InstanceId"
aws ec2 terminate-instances --instance-ids $InstanceId

Write-Output "Instance $InstanceId has been terminated successfully."

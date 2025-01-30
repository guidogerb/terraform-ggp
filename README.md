# terraform-ggp
Terraform GuidoGerb Publishing, LLC
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

# start and stop ec2-p5-48xlarge

aws ec2 stop-instances --instance-ids i-xxxxxxxxxxxxxxxx

aws ec2 start-instances --instance-ids i-xxxxxxxxxxxxxxxx

# terraform-ggp
Terraform GuidoGerb Publishing, LLC
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

# 74.213.199.191

# start and stop ec2-p5-48xlarge

aws ec2 stop-instances --instance-ids i-0d46cdc38826bf1a1

aws ec2 start-instances --instance-ids i-0d46cdc38826bf1a1

aws ssm start-session --target i-0d46cdc38826bf1a1

s3fs ggp-us-east-2-provision-ec2-s3-buckets-ec2-data-bucket ~/s3-home -o iam_role=auto -o allow_other -o umask=0022


aws service-quotas list-service-quotas --service-code ec2 --region us-east-2
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A --region us-east-2

aws service-quotas request-service-quota-increase --service-code ec2 --quota-code L-1216C47A --desired-value 1 --region us-east-2


Subject: Increase Request for p5.48xlarge Instance Quota in us-east-2

Dear AWS Support,

I am requesting a quota increase for the p5.48xlarge instance type in the us-east-2 region. Currently, I am experiencing insufficient capacity errors while launching these instances, which is impacting my workload.

### Use Case:
I am running AI model training and inference workloads using DeepSeek-R1 (67B) and Mistral models. These require high VRAM and multi-GPU setups, making p5.48xlarge an essential resource.

### Requested Increase:
- Instance Type: p5.48xlarge
- Current Limit: 0 (or low)
- Requested Limit: 2-4 instances
- Region: us-east-2 (but flexible if needed)

### Business Impact:
- Delays in AI model inference and research
- Increased compute costs due to inefficiencies in smaller instance types
- Reduced scalability and performance in our application

If there are alternative availability zones or recommended solutions, please let me know.

Thank you for your assistance.

Best regards,  
[Your Name]  
[Your Company / Project Name]  
[Your AWS Account ID]


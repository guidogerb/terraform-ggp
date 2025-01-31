output "deepseek-sg-id" {
  description = "Deepseek Security Group ID"
  value       = aws_security_group.deepseek_sg.id
}

output "gpu-role-name" {
  description = "Deepseek GPU IAM Role Name"
  value       = aws_iam_instance_profile.iam-instance-profile-gpu-role.name
}
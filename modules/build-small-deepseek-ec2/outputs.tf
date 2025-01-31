output "deepseek-ami" {
  value = aws_ami_from_instance.deepseek-complete-ami.id
  description = "The AMI of the newly created DeepSeek-AMI."
}
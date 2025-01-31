output "deepseek-ami" {
  value = aws_ami.deepseek_ami.id
  description = "The AMI of the newly created DeepSeek-AMI."
}
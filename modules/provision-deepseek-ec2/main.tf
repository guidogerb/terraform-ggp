/*### LAUNCH PRODUCTION INSTANCE ON INF2.48XLARGE
resource "aws_instance" "deepseek_inference" {
  ami           = var.ec2-ami
  instance_type = "inf2.48xlarge"
  key_name      = var.key-pair

  root_block_device {
    volume_size = 100  # Root volume for OS
    volume_type = "gp3"
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 2000  # 2TB storage for model & vLLM cache
    volume_type           = "gp3"
    delete_on_termination = false
  }

  vpc_security_group_ids = [aws_security_group.deepseek_sg.id]
  iam_instance_profile = aws_iam_instance_profile.gpu_role.name

  tags = {
    Name = "DeepSeek-Inference-Server"
  }
}
*/
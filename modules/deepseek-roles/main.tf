resource "aws_security_group" "deepseek_sg" {
  name        = "${var.prepend-name}deepseek-sg"
  description = "Allow SSH and inference API traffic"
  vpc_id = var.vpc-id

  # SSH Access
  ingress {
    from_port   = var.ingress-ssh-port
    to_port     = var.ingress-ssh-port
    protocol    = "tcp"
    cidr_blocks = ["${var.my-ip}/32"]
  }

  # Inference API ports
  ingress {
    from_port   = var.ingress-inference-start-port
    to_port     = var.ingress-inference-end-port
    protocol    = "tcp"
    cidr_blocks = ["${var.my-ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.prepend-name}deepseek-sg"
  })
}

resource "aws_iam_role" "gpu_role" {
  name = "${var.prepend-name}gpu-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(local.tags, {
    Name = "${var.prepend-name}gpu-role"
  })
}

resource "aws_iam_policy_attachment" "gpu_policy" {
  name       = "${var.prepend-name}gpu-policy-attachment"
  roles      = [aws_iam_role.gpu_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "iam-instance-profile-gpu-role" {
  name = "${var.prepend-name}iam-instance-profile-gpu-role"
  role = aws_iam_role.gpu_role.name

  tags = merge(local.tags, {
    Name = "${var.prepend-name}iam-instance-profile-gpu-role"
  })
}


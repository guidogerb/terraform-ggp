# 🎯 EC2 Instance
resource "aws_instance" "aws-instance" {
  ami                    = var.ec2-ami
  instance_type          = var.instance-type
  key_name               = var.key-pair
  subnet_id              = var.subnet_id
  monitoring             = false
  hibernation            = false
  disable_api_termination = false
  ebs_optimized          = true
  iam_instance_profile   = var.ec2-instance-profile-name
  count = var.start-instance? 1:0

  root_block_device {
    volume_size           = 256
    volume_type           = "gp3"
    delete_on_termination = false
  }

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    sudo dnf update -y
    sudo dnf groupinstall "Development Tools" -y
    sudo dnf install fuse fuse-devel libcurl-devel libxml2-devel openssl-devel -y
    sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent

    # download and compile, install and mount s3 with s3fs-fuse
    mkdir ~/sources
    cd ~/sources
    git clone https://github.com/s3fs-fuse/s3fs-fuse.git
    cd s3fs-fuse
    ./autogen.sh
    ./configure --prefix=/usr --with-openssl
    make
    sudo make install
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf
    sudo chmod 644 /etc/fuse.conf

    # Create a directory for mounting
    mkdir ~/s3-home

    # Mount the S3 bucket using the IAM role
    s3fs ${var.ec2_data_bucket_name} ~/s3-home -o iam_role=auto -o allow_other -o umask=0022

    # Auto-mount on reboot
    echo "s3fs#${var.ec2_data_bucket_name} ~/s3-home fuse _netdev,allow_other,use_path_request_style,iam_role=auto,umask=0022 0 0" | sudo tee -a /etc/fstab

  EOF

  tags = merge(local.tags, {
    Name = "${var.prepend-name}aws-instance"
  })

}

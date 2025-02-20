### FIND LATEST AWS NEURON AMI FOR INFERENCE
data "aws_ami" "deep_learning_neuron" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = var.most-recent-deep-learning-image-regex
  }
}

### build instance (inf2.48xlarge or greater needed)
resource "aws_instance" "deepseek-complete-builder" {
  # use the provided AMI if present, else find the latest
  ami           = coalesce(var.ec2-ami, data.aws_ami.deep_learning_neuron.id)
  instance_type = var.instance-type
  key_name      = var.key-pair

  subnet_id = var.subnet_id
  # Security Group - Open SSH, HTTP for inference API, and Jupyter
  vpc_security_group_ids = [var.deepseek-sg-id]

  root_block_device {
    volume_size = 400  # Root volume for OS and dependencies
    volume_type = "gp3"
  }

  # Model storage EBS volume (2TB for DeepSeek-R1:671B + vLLM caching)
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 2000  # 2TB storage
    volume_type           = "gp3"
    delete_on_termination = false
  }

  iam_instance_profile = var.gpu-role-name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    cat << 'EOF' >> ~/.bashrc

export PATH="/usr/bin:/bin:$PATH"
EOF

    source .bashrc

    echo "#############################################################" >> /tmp/setup.log
    echo "[$(date)] Starting DeepSeek models setup..." >> /tmp/setup.log

    # Update system packages
    sudo apt update && sudo apt upgrade -y
    sudo apt dist-upgrade -y
    sudo apt install --only-upgrade linux-aws linux-headers-aws linux-image-aws
    do-release-upgrade
    # Additional ssh port 1022 started in case of failure
    # Some third party entries in your sources.list were disabled. You can
    # re-enable them after the upgrade with the 'software-properties' tool
    # or your package manager.


    ########################
    # Install AWS Neuron SDK
    . /etc/os-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL "https://apt.repos.neuron.amazonaws.com/GPG-PUB-KEY-AMAZON-AWS-NEURON.PUB" | sudo gpg --dearmor -o /etc/apt/keyrings/neuron.gpg
    sudo tee /etc/apt/sources.list.d/neuron.list > /dev/null <<EOF deb [arch=amd64 signed-by=/etc/apt/keyrings/neuron.gpg] https://apt.repos.neuron.amazonaws.com jammy main EOF

    wget -qO - "https://apt.repos.neuron.amazonaws.com/GPG-PUB-KEY-AMAZON-AWS-NEURON.PUB" | sudo apt-key add -
    sudo apt update -y
    sudo apt install aws-neuronx-dkms -y
    sudo apt install aws-neuronx-runtime-lib -y
    sudo apt install -y aws-neuronx-tools aws-neuronx-dkms aws-neuronx-runtime-lib
    sudo apt update -y

    # Verify Neuron SDK Installation
    if dpkg -l | grep -q aws-neuronx-runtime-lib; then
        echo "✅ Neuron SDK installed successfully." >> /tmp/setup.log
    else
        echo "❌ ERROR: Neuron SDK installation failed!" >> /tmp/setup.log
        exit 1
    fi

    # Install Python & Pip dependencies
    sudo apt update
    sudo apt install -y \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    mkdir sources
    cd sources
    wget https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh
    bash Anaconda3-2024.10-1-Linux-x86_64.sh
    python3 -m pip install --upgrade pip
    python3 -m pip install torch torchvision torchaudio vllm[neuron] transformers

    # Install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    export PATH="$HOME/.ollama/bin:$PATH"
    echo 'export PATH="$HOME/.ollama/bin:$PATH"' >> ~/.bashrc

    # Install AWS SSM Agent
    sudo snap install amazon-ssm-agent --classic

    echo "Installing S3FS and configuring IAM role-based access..." >> /tmp/setup.log

    ########################
    # Install S3FS
    sudo apt install -y s3fs

    cd ~
    mkdir sources
    cd sources
    mkdir models
    mkdir pythons
    mkdir s3
    cd /mnt/models

    df -h # display file system available storage

    ollama pull deepseek-r1:671b
    ollama run <model_name> --prompt "hello world"

    git clone https://huggingface.co/deepseek-ai/deepseek-llm-67b-chat
    git clone https://huggingface.co/deepseek-ai/deepseek-llm-7b-chat
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Llama-70B
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-14B

    du -h --max-depth=100 . | sort -h
    du -h --max-depth=100 /usr/share/ollama/.ollama/models | sort -h



    ########################
    # 🔹 Create Systemd Service for Ollama
    sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOT
    [Unit]
    Description=Ollama Model Server
    After=network.target

    [Service]
    ExecStart=/usr/local/bin/ollama serve
    Restart=always
    RestartSec=5
    StartLimitIntervalSec=500
    StartLimitBurst=5
    User=ubuntu
    WorkingDirectory=/home/ubuntu

    [Install]
    WantedBy=multi-user.target
    EOT

    # 🔹 Create Systemd Service for Ollama Model Run
    sudo tee /etc/systemd/system/ollama-run.service > /dev/null <<EOT
    [Unit]
    Description=Ollama Model Runner
    After=ollama.service

    [Service]
    ExecStart=/usr/local/bin/ollama run deepseek-r1:671b > /dev/null 2>&1
    Restart=always
    RestartSec=5
    StartLimitIntervalSec=500
    StartLimitBurst=5
    User=ubuntu
    WorkingDirectory=/home/ubuntu

    [Install]
    WantedBy=multi-user.target
    EOT

    # 🔹 Create Systemd Services for vLLM API Servers
    for model in "DeepSeek-R1-Distill-Llama-70B:11435" \
                 "DeepSeek-R1-Distill-Qwen-32B:11436" \
                 "DeepSeek-R1-Distill-Qwen-14B:11437" \
                 "deepseek-llm-67b-chat:11438" \
                 "deepseek-llm-7b-chat:11439"
    do
        model_name=$(echo $model | cut -d':' -f1)
        port=$(echo $model | cut -d':' -f2)

        sudo tee /etc/systemd/system/vllm-$model_name.service > /dev/null <<EOT
        [Unit]
        Description=vLLM API Server for $model_name
        After=network.target

        [Service]
        ExecStart=/usr/bin/python3 -m vllm.entrypoints.openai.api_server --model /mnt/models/$model_name --port $port
        Restart=always
        RestartSec=5
        StartLimitIntervalSec=500
        StartLimitBurst=5
        User=ubuntu
        WorkingDirectory=/home/ubuntu

        [Install]
        WantedBy=multi-user.target
        EOT
    done

    ########################
    # Create systemd service for S3 mount
    sudo tee /etc/systemd/system/mount-s3.service > /dev/null <<EOT
    [Unit]
    Description=Mount S3 Bucket using s3fs
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/s3fs ${var.ec2_data_bucket_name} /mnt/s3 -o iam_role=auto,allow_other,use_cache=/tmp
    ExecStop=/bin/fusermount -u /mnt/s3
    Restart=always
    RestartSec=5
    StartLimitIntervalSec=500
    StartLimitBurst=5
    User=ubuntu

    [Install]
    WantedBy=multi-user.target
    EOT

    # Reload systemd to recognize new services
    sudo systemctl daemon-reload

    # Enable Services
    sudo systemctl enable amazon-ssm-agent ollama ollama-run mount-s3.service

    for model in "DeepSeek-R1-Distill-Llama-70B" \
                 "DeepSeek-R1-Distill-Qwen-32B" \
                 "DeepSeek-R1-Distill-Qwen-14B" \
                 "deepseek-llm-67b-chat" \
                 "deepseek-llm-7b-chat"
    do
        sudo systemctl enable vllm-$model
    done

    ########################
    echo "Configuring SSH to run on a different port..." >> /tmp/setup.log

    SSH_PORT="${var.ssh-port}"

    echo "Configuring SSH to run on port $SSH_PORT..." >> /tmp/setup.log

    # Update SSH configuration to use the new port
    sudo sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    sudo sed -i "s/^Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

    # Restart SSH service to apply changes
    sudo systemctl restart sshd

    # Allow the new SSH port in security settings (if UFW is installed)
    sudo ufw allow $SSH_PORT/tcp || echo "UFW not installed, skipping..."

    echo "SSH is now running on port $SSH_PORT" >> /tmp/setup.log

    # Setup complete
    echo "[$(date)] DeepSeek models setup complete." >> /tmp/setup.log
    echo "#############################################################" >> /tmp/setup.log
  EOF

  tags = merge(local.tags, {
    Name = "${var.prepend-name}DeepSeek-Builder-Inf2"
  })
}

resource "aws_ami_from_instance" "deepseek-complete-ami" {
  depends_on = [aws_instance.deepseek-complete-builder]
  name        = "${var.prepend-name}DeepSeek-Complete-AMI"
  description = "AMI with DeepSeek inference setup"
  source_instance_id = aws_instance.deepseek-complete-builder.id

  tags = merge(local.tags, {
    Name = "${var.prepend-name}DeepSeek-Complete-AMI"
  })
}

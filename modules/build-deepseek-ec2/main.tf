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

  # Security Group - Open SSH, HTTP for inference API, and Jupyter
  vpc_security_group_ids = [var.deepseek-sg-id]

  iam_instance_profile = var.gpu-role-name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    echo "#############################################################" >> /tmp/setup.log
    echo "[$(date)] Starting DeepSeek models setup..." >> /tmp/setup.log

    # Update system packages
    sudo apt update && sudo apt upgrade -y

    ########################
    # Install AWS Neuron SDK
    sudo apt install -y aws-neuronx-tools aws-neuronx-dkms aws-neuronx-runtime-lib neuronx-cc neuronx-runtime

    # Verify Neuron SDK Installation
    if dpkg -l | grep -q aws-neuronx-runtime-lib; then
        echo "✅ Neuron SDK installed successfully." >> /tmp/setup.log
    else
        echo "❌ ERROR: Neuron SDK installation failed!" >> /tmp/setup.log
        exit 1
    fi

    # Install Python & Pip dependencies
    sudo apt install -y python3-pip
    python3 -m pip install --upgrade pip
    python3 -m pip install torch torchvision torchaudio vllm transformers

    # Install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    export PATH="$HOME/.ollama/bin:$PATH"
    echo 'export PATH="$HOME/.ollama/bin:$PATH"' >> ~/.bashrc

    # Install AWS SSM Agent
    sudo snap install amazon-ssm-agent --classic

    ########################
    # create models folder and download
    mkdir -p /mnt/models
    sudo chown ubuntu:ubuntu /mnt/models
    cd /mnt/models

    ollama pull deepseek-r1:671b

    git clone https://huggingface.co/deepseek-ai/deepseek-llm-67b-chat
    git clone https://huggingface.co/deepseek-ai/deepseek-llm-7b-chat
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Llama-70B
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-14B

    ########################
    # 🔹 Create Systemd Service for Ollama
    sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOT
    [Unit]
    Description=Ollama Model Server
    After=network.target

    [Service]
    ExecStart=/usr/local/bin/ollama serve
    Restart=always
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
        User=ubuntu
        WorkingDirectory=/home/ubuntu

        [Install]
        WantedBy=multi-user.target
        EOT
    done

    # Reload systemd to recognize new services
    sudo systemctl daemon-reload

    # Enable Services
    sudo systemctl enable amazon-ssm-agent ollama ollama-run

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

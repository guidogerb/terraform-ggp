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
    volume_size = 100  # Root volume for OS and dependencies
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

    # Install AWS Neuron SDK
    sudo apt install -y aws-neuronx-tools aws-neuronx-dkms aws-neuronx-runtime-lib neuronx-cc neuronx-runtime

    # Install Python & Pip dependencies
    sudo apt install -y python3-pip
    python3 -m pip install --upgrade pip
    python3 -m pip install torch torchvision torchaudio vllm transformers

    # Install and run Ollama Model deepseek-r1:671b
    mkdir -p /mnt/ollama
    sudo chown ubuntu:ubuntu /mnt/ollama
    cd /mnt/ollama
    curl -fsSL https://ollama.com/install.sh | sh
    ollama pull deepseek-r1:671b
    ollama serve
    ollama run deepseek-r1:671b

    # Install Huggingface DeepSeek models
    mkdir -p /mnt/deepseek
    sudo chown ubuntu:ubuntu /mnt/deepseek
    cd /mnt/deepseek

    git clone https://huggingface.co/deepseek-ai/deepseek-llm-67b-chat
    git clone https://huggingface.co/deepseek-ai/deepseek-llm-7b-chat
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Llama-70B
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-14B

    # Test - load models
    python3 -m vllm.model_loader --model-path ./deepseek-llm-67b-chat --preload
    python3 -m vllm.model_loader --model-path ./deepseek-llm-7b-chat --preload
    python3 -m vllm.model_loader --model-path ./DeepSeek-R1-Distill-Llama-70B --preload
    python3 -m vllm.model_loader --model-path ./DeepSeek-R1-Distill-Qwen-32B --preload
    python3 -m vllm.model_loader --model-path ./DeepSeek-R1-Distill-Qwen-14B --preload

    sudo systemctl restart neuron-rtd
    sync; echo 3 | sudo tee /proc/sys/vm/drop_caches

    # Setup complete
    echo "[$(date)] DeepSeek models setup complete." >> /tmp/setup.log
    echo "#############################################################" >> /tmp/setup.log
  EOF

  tags = merge(local.tags, {
    Name = "${var.prepend-name}DeepSeek-Builder-Inf2"
  })
}

### CREATE AMI AFTER SETUP
resource "aws_ami" "deepseek_ami" {
  name                = "${var.prepend-name}DeepSeek-AMI"
  instance_id         = aws_instance.deepseek-complete-builder.id
  description         = "Preconfigured AMI for comprehensive DeepSeek model inference on Inf2"
  virtualization_type = "hvm"

  tags = merge(local.tags, {
    Name = "${var.prepend-name}DeepSeek-AMI"
  })
}

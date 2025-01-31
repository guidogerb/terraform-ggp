# terraform-ggp
Terraform GuidoGerb Publishing, LLC
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

# 74.213.199.191

# start and stop 



aws ec2 stop-instances --instance-ids i-0d46cdc38826bf1a1

aws ec2 start-instances --instance-ids i-0d46cdc38826bf1a1

aws ssm start-session --target i-0d46cdc38826bf1a1

s3fs ggp-us-east-2-provision-ec2-s3-buckets-ec2-data-bucket ~/s3-home -o iam_role=auto -o allow_other -o umask=0022


aws service-quotas list-service-quotas --service-code ec2 --region us-east-2
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A --region us-east-2

aws service-quotas request-service-quota-increase --service-code ec2 --quota-code L-1216C47A --desired-value 1 --region us-east-2

Here’s a **Terraform configuration** to build an **AWS AMI on `inf2.xlarge`**, optimized for **DeepSeek-R1:671B (404GB model)**, and later deploy it on an **`inf2.48xlarge`** instance.

### **Key Considerations:**
1. **Base AMI**: We use **AWS Deep Learning AMI Neuron (Ubuntu 22.04)**, optimized for **AWS Inferentia2 (INF2) instances**.
2. **EBS Storage**:
    - **Root volume:** 100GB (`gp3`)
    - **Model storage:** 2TB (`gp3`) for **DeepSeek-R1:671B (404GB) + vLLM caching**
3. **Software Setup**:
    - **Neuron SDK** (AWS Inferentia drivers)
    - **vLLM** (Optimized model serving framework)
    - **DeepSeek model & dependencies**
4. **AMI Creation**:
    - Once the instance is configured, it generates a **custom AMI** for launching on `inf2.48xlarge`.

---

### **Terraform Configuration**
```hcl
provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

### FIND LATEST AWS NEURON AMI FOR INFERENCE
data "aws_ami" "deep_learning_neuron" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning AMI Neuron Ubuntu 22.04*"]
  }
}

### BUILD INSTANCE ON INF2.XLARGE
resource "aws_instance" "deepseek_builder" {
  ami           = data.aws_ami.deep_learning_neuron.id
  instance_type = "inf2.xlarge"
  key_name      = "my-keypair"  # Replace with your SSH key

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
  vpc_security_group_ids = [aws_security_group.deepseek_sg.id]

  iam_instance_profile = aws_iam_instance_profile.gpu_role.name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system packages
    sudo apt update && sudo apt upgrade -y

    # Install AWS Neuron SDK
    sudo apt install -y aws-neuronx-tools aws-neuronx-dkms aws-neuronx-runtime-lib

    # Install Python & Pip dependencies
    sudo apt install -y python3-pip
    python3 -m pip install --upgrade pip
    python3 -m pip install torch torchvision torchaudio vllm transformers

    # Install DeepSeek model
    mkdir -p /mnt/deepseek
    sudo chown ubuntu:ubuntu /mnt/deepseek
    cd /mnt/deepseek
    git clone https://huggingface.co/deepseek-ai/deepseek-llm-67b-chat
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Llama-70B
    git clone https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
    cd deepseek-llm-67b-chat

    # Run model setup (if required)
    python3 -m vllm.model_loader --model-path . --preload

    # Setup complete
    echo "DeepSeek model setup complete" > /tmp/setup.log
  EOF

  tags = {
    Name = "DeepSeek-Builder-Inf2"
  }
}

### CREATE AMI AFTER SETUP
resource "aws_ami" "deepseek_ami" {
  name                = "DeepSeek-AMI"
  instance_id         = aws_instance.deepseek_builder.id
  description         = "Preconfigured AMI for DeepSeek-R1:671B inference on Inf2"
  virtualization_type = "hvm"

  tags = {
    Name = "DeepSeek-AMI"
  }
}

### LAUNCH PRODUCTION INSTANCE ON INF2.48XLARGE
resource "aws_instance" "deepseek_inference" {
  ami           = aws_ami.deepseek_ami.id
  instance_type = "inf2.48xlarge"
  key_name      = "my-keypair"
  
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

### SECURITY GROUP: ALLOW SSH, API TRAFFIC
resource "aws_security_group" "deepseek_sg" {
  name        = "deepseek-sg"
  description = "Allow SSH and inference API traffic"

  ingress {
    from_port   = 22  # SSH Access
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000  # Inference API port (customize if needed)
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### IAM ROLE FOR INF2 INSTANCE
resource "aws_iam_role" "gpu_role" {
  name = "gpu-instance-role"

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
}

resource "aws_iam_policy_attachment" "gpu_policy" {
  name       = "gpu-policy-attachment"
  roles      = [aws_iam_role.gpu_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "gpu_role" {
  name = "gpu-instance-profile"
  role = aws_iam_role.gpu_role.name
}
```

---

## **Workflow**
1. **Terraform creates an `inf2.xlarge` instance** and installs:
    - AWS **Neuron SDK** (for Inferentia2 acceleration).
    - **vLLM** (optimized for DeepSeek inference).
    - **DeepSeek-R1:671B model** (downloaded from Hugging Face).
    - Python dependencies.

2. **AMI is created from this configured instance**.

3. **A new `inf2.48xlarge` instance is launched** from this AMI:
    - Uses a **2TB EBS volume** for DeepSeek model storage & vLLM caching.
    - Runs inference workloads with optimized Neuron runtime.

---

## **Why This Approach?**
✅ **Cost-Effective Development** → `inf2.xlarge` is cheaper for setup.  
✅ **Scalability** → Prepares an optimized AMI that can scale across **inf2.48xlarge** instances.  
✅ **Performance Optimized** → Uses **AWS Neuron SDK** and **vLLM** for **fast inference**.  
✅ **Reproducible** → Any new instance can use the prebuilt AMI for instant deployment.

Let me know if you need further refinements! 🚀

    # query ollama
    curl -X POST "http://localhost:11434/api/generate" -H "Content-Type: application/json" \
      -d '{"model": "deepseek-r1:671b", "prompt": "Without thinking, say hello", "stream": false}' \
        >> /tmp/setup.log 2>&1

    # Query vllm.entrypoints.openai.api_server
    curl -X POST "http://localhost:8001/v1/completions" -H "Content-Type: application/json" \
    -d '{"model": "deepseek-r1-67b", "prompt": "What is quantum computing?", "max_tokens": 100}'
    

ollama serve &
ollama run deepseek-r1:671b > /dev/null 2>&1 &

python3 -m vllm.entrypoints.openai.api_server --model /mnt/deepseek/DeepSeek-R1-Distill-Llama-70B --port 11435 &
python3 -m vllm.entrypoints.openai.api_server --model /mnt/deepseek/DeepSeek-R1-Distill-Qwen-32B --port 11436 &
python3 -m vllm.entrypoints.openai.api_server --model /mnt/deepseek/DeepSeek-R1-Distill-Qwen-14B --port 11437 &

python3 -m vllm.entrypoints.openai.api_server --model /mnt/deepseek/deepseek-llm-67b-chat --port 11438 &
python3 -m vllm.entrypoints.openai.api_server --model /mnt/deepseek/deepseek-llm-7b-chat --port 11439 &


    # Test - load models
    python3 -m vllm.model_loader --model-path ./deepseek-llm-67b-chat --preload
    python3 -m vllm.model_loader --model-path ./deepseek-llm-7b-chat --preload
    python3 -m vllm.model_loader --model-path ./DeepSeek-R1-Distill-Llama-70B --preload
    python3 -m vllm.model_loader --model-path ./DeepSeek-R1-Distill-Qwen-32B --preload
    python3 -m vllm.model_loader --model-path ./DeepSeek-R1-Distill-Qwen-14B --preload

    sudo systemctl restart neuron-rtd
    sync; echo 3 | sudo tee /proc/sys/vm/drop_caches

# Use the NVIDIA CUDA 12.6.0 image with cuDNN 8 based on Ubuntu 22.04
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation.
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies required for installing Miniconda
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    bzip2 \
    curl \
    ca-certificates \
    openssh-server sudo \
 && rm -rf /var/lib/apt/lists/*

# Install Miniconda
ENV CONDA_DIR=/opt/anaconda
# deepseek-r1:671b deepseek-r1:70b deepseek-r1:32b deepseek-r1:14b deepseek-r1:8b deepseek-r1:7b deepseek-r1:1.5b
ENV MODEL=deepseek-r1:70b

RUN curl -O https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh && \
    bash Anaconda3-2023.09-0-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm -f Anaconda3-2023.09-0-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda clean -ay

# Add conda to PATH
ENV PATH=$CONDA_DIR/bin:$PATH

# (Optional) Update conda
RUN conda update -n base -c defaults conda -y && \
    pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126 && \
    conda install nvidia/label/cuda-12.6.3::cuda-toolkit


RUN useradd -ms /bin/bash ggerber && \
    mkdir -p /home/ggerber/.ssh && \
    chown ggerber:ggerber /home/ggerber/.ssh && \
    chmod 700 /home/ggerber/.ssh

COPY ggp-ec2-key.pub /home/ggerber/.ssh/authorized_keys

RUN chown ggerber:ggerber /home/ggerber/.ssh/authorized_keys && \
    chmod 600 /home/ggerber/.ssh/authorized_keys  && \
    usermod -aG sudo ggerber && \
    echo "sshuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ggerber && \
    chmod 0440 /etc/sudoers.d/ggerber

# Start the SSH service
RUN mkdir /var/run/sshd
RUN chmod 0755 /var/run/sshd

# Modify sshd_config to disable password authentication and root login
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Install ollama
RUN curl -fsSL https://ollama.com/install.sh | sh
# RUN ollama pull $MODEL

########################
# Create the Ollama service file using a heredoc
RUN tee /etc/systemd/system/ollama.service > /dev/null <<'EOF'
[Unit]
Description=Ollama Model Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=5
StartLimitIntervalSec=500
StartLimitBurst=5
User=ggerber
WorkingDirectory=/home/ggerber

[Install]
WantedBy=multi-user.target
EOF

# Enable ollama services
RUN systemctl enable ollama.service

# Set workdir
WORKDIR /home/ggerber

# Expose SSH port
EXPOSE 22

# Enable the SSHD service so systemd starts it automatically
RUN systemctl enable sshd.service && systemctl enable ollama.service

# Mount cgroups for systemd to work properly
VOLUME [ "/sys/fs/cgroup" ]


CMD ["/sbin/init"]

# docker-compose up -d

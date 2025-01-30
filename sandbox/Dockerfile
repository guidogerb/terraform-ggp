# Use an official Ubuntu image as the base
FROM ubuntu:22.04

# Set a non-interactive frontend for automated installs
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update && apt install -y \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.ai/install.sh | sh

# Ensure Ollama is in the PATH
ENV PATH="/root/.ollama/bin:$PATH"

# Pull a model (Change 'deepseek-r1:67b' to your preferred model)
RUN ollama pull deepseek-r1:67b

# Expose the API port
EXPOSE 11434

# Start Ollama API server
CMD ["ollama", "serve"]

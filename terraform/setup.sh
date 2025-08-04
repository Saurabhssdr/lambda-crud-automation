#!/bin/bash

# Update and install dependencies
yum update -y
yum install -y git docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group (no reboot needed if service is running)
usermod -aG docker ec2-user
newgrp docker  # Apply group change immediately

# Clone repo
cd /home/ec2-user
git clone https://github.com/Saurabhssdr/lambda-crud-automation.git || (cd lambda-crud-automation && git pull)
cd lambda-crud-automation

# Set permissions
chown -R ec2-user:ec2-user /home/ec2-user/lambda-crud-automation
chmod -R 755 /home/ec2-user/lambda-crud-automation

# Rename dockerfile if needed
[ -f dockerfile ] && mv dockerfile Dockerfile

# Build and run Docker container
docker build -t fastapi-crud .
docker run -d -p 8000:80 --restart unless-stopped --name fastapi-crud fastapi-crud

#!/bin/bash

# Update and install dependencies
yum update -y
yum install -y git docker

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group and reboot to apply (handled by cloud-init)
usermod -aG docker ec2-user
reboot

# Clone repo (will run after reboot via user_data)
cd /home/ec2-user
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api

# Set permissions
chown ec2-user:ec2-user /home/ec2-user/fast-api
chmod 755 /home/ec2-user/fast-api

# Build and run Docker container
docker build -t fastapi-crud .
docker run -d -p 8000:80 --restart unless-stopped --name fastapi-crud fastapi-crud


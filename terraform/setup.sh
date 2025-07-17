#!/bin/bash

yum update -y
yum install -y git docker
systemctl start docker
systemctl enable docker

cd /home/ec2-user
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api

chown ec2-user:ec2-user /home/ec2-user/fast-api
chmod 755 /home/ec2-user/fast-api

# Build and run Docker image
docker build -t fastapi-crud .
docker run -d -p 8000:80 fastapi-crud



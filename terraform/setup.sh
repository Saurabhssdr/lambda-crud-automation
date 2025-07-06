#!/bin/bash
 
# Update and install required tools
yum update -y
yum install -y git python3-pip
 
# Go to ec2-user home
cd /home/ec2-user
 
# Clone the FastAPI repo
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api
 
# Set ownership and permissions
chown -R ec2-user:ec2-user /home/ec2-user/fast-api
chmod -R 755 /home/ec2-user/fast-api
 
# Install Python dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt || pip3 install fastapi uvicorn boto3 python-dotenv httpx
 
# Start FastAPI in background
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &

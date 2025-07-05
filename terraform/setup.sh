#!/bin/bash
 
# Update system & install essentials
yum update -y
yum install -y git python3-pip
 
# Navigate to home
cd /home/ec2-user
 
# Clone repo
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api
git checkout main
 
# Ensure .env is present
if [ ! -f ".env" ]; then
    echo "❌ .env file missing in the repo. Exiting."
    exit 1
fi
 
# Install Python dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt || pip3 install fastapi uvicorn boto3 python-dotenv httpx
 
# Run app in background & write logs
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &


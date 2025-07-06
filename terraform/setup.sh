#!/bin/bash
 
yum update -y
yum install -y git python3-pip
 
cd /home/ec2-user
 
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api
 
chown ec2-user:ec2-user /home/ec2-user/fast-api
chmod 755 /home/ec2-user/fast-api
 
pip3 install --upgrade pip
pip3 install -r requirements.txt || pip3 install fastapi uvicorn boto3 python-dotenv httpx
 
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &

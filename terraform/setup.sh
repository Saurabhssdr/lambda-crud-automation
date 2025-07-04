#!/bin/bash
yum update -y
yum install -y git python3 pip
cd /home/ec2-user
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api
git checkout main
pip3 install --upgrade pip
pip3 install httpx fastapi uvicorn boto3 python-dotenv
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &
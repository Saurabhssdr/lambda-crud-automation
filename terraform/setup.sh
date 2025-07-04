#!/bin/bash
yum update -y
yum install -y git python3 pip
cd /home/ec2-user
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api
git checkout main
# Make sure .env is present
if [ ! -f ".env" ]; then
  echo ".env file missing. Exiting setup."
  exit 1
fi
pip3 install --upgrade pip
pip3 install -r requirements.txt || pip3 install httpx fastapi uvicorn boto3 python-dotenv
 
export AWS_ACCESS_KEY_ID=your-access-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-key
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &
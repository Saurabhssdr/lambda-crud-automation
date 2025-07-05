#!/bin/bash
 
# Update system packages
yum update -y
 
# Install necessary tools
yum install -y git python3-pip
 
# Navigate to home directory
cd /home/ec2-user
 
# Clone the FastAPI repo
git clone https://github.com/Saurabhssdr/fast-api.git
 
# Move into the cloned repo
cd fast-api
 
# Checkout main branch
git checkout main
 
# Ensure .env exists
if [ ! -f ".env" ]; then
  echo ".env file missing. Exiting setup."
  exit 1
fi
 
# Export AWS credentials from .env
export $(grep AWS_ACCESS_KEY_ID .env)
export $(grep AWS_SECRET_ACCESS_KEY .env)
 
# Optional: echo to confirm they're loaded (comment out in prod)
echo "Access Key: $AWS_ACCESS_KEY_ID"
echo "Secret Key: $AWS_SECRET_ACCESS_KEY"
 
# Upgrade pip and install dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt || pip3 install fastapi uvicorn boto3 python-dotenv httpx
 
# Start FastAPI in background and log output
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > /home/ec2-user/fast-api/fastapi.log 2>&1 &
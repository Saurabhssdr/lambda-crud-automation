#!/bin/bash
 
# Update system & install essentials
yum update -y
yum install -y git python3-pip
 
# Navigate to home
cd /home/ec2-user
 
# Clone repo
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api

# Create .env file with placeholders
cat << 'EOF' > /home/ec2-user/fast-api/.env
AWS_ACCESS_KEY_ID= #AWS_ACCESS_KEY_ID#
AWS_SECRET_ACCESS_KEY= #AWS_SECRET_ACCESS_KEY#
AWS_DEFAULT_REGION= #AWS_DEFAULT_REGION#
EOF

# Ensure .env is created
if [ ! -f ".env" ]; then
    echo "❌ .env file creation failed. Exiting."
    exit 1
fi

sed -i 's/#AWS_ACCESS_KEY_ID#/AKIA2L32X3A2J362ZXSB/g' /home/ec2-user/fast-api/.env
sed -i 's/#AWS_SECRET_ACCESS_KEY#/SID6XPTVWGmWbwUMzZXZGamZ8Dro4kY1+194fAN/g' /home/ec2-user/fast-api/.env
sed -i 's/#AWS_DEFAULT_REGION#/us-east-1/g' /home/ec2-user/fast-api/.env

 
# Install Python dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt || pip3 install fastapi uvicorn boto3 python-dotenv httpx
 
# Run app in background & write logs
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &


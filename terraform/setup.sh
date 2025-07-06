setup.sh file 
 
#!/bin/bash
 
# Update system & install essentials
yum update -y
yum install -y git python3-pip
 
# Navigate to home
cd /home/ec2-user
 
# Clone repo
git clone https://github.com/Saurabhssdr/fast-api.git
cd fast-api
sudo chown ec2-user:ec2-user /home/ec2-user/fast-api
sudo chmod 755 /home/ec2-user/fast-api
 
# No .env creation needed now
# No sed replacement
 
# Install dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt || pip3 install fastapi uvicorn boto3 python-dotenv httpx
 
# Start FastAPI app
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &

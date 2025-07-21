# #!/bin/bash

# # Update and install dependencies
# yum update -y
# yum install -y git docker
# systemctl start docker
# systemctl enable docker

# # Add ec2-user to docker group (no reboot needed if service is running)
# usermod -aG docker ec2-user
# newgrp docker  # Apply group change immediately

# # Clone repo
# cd /home/ec2-user
# git clone https://github.com/Saurabhssdr/fast-api.git || (cd fast-api && git pull)
# cd fast-api

# # Set permissions
# chown -R ec2-user:ec2-user /home/ec2-user/fast-api
# chmod -R 755 /home/ec2-user/fast-api

# # Rename dockerfile if needed
# [ -f dockerfile ] && mv dockerfile Dockerfile

# # Build and run Docker container
# docker build -t fastapi-crud .
# docker run -d -p 8000:80 --restart unless-stopped --name fastapi-crud fastapi-crud

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


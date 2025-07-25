📄 FastAPI CRUD Deployment on AWS

📝 Description

A robust FastAPI CRUD application deployed on AWS, automating data management with:





CRUD operations stored in DynamoDB



Endpoints exposed via Swagger UI on an EC2 public IP



Fully provisioned using Terraform (IaC) and automated with Jenkins

🧭 How It Works (Architecture Overview)





🟩 EC2: Hosts the Dockerized FastAPI app, provisioned by Terraform.



🟨 Docker: Runs the FastAPI container with CRUD endpoints.



🟦 DynamoDB: Stores CRUD data persistently.



🟧 Swagger UI: Exposes endpoints at http://<ec2-public-ip>:8000/docs for browser-based CRUD.



🟪 Terraform: Defines EC2, security groups, and IAM roles.



⚙️ Jenkins: Automates the deployment pipeline.



🛡️ Security Groups: Controls port 8000 access.

🧰 AWS Services Used





Amazon EC2



Amazon DynamoDB



Docker



Terraform (IaC)



Jenkins (CI/CD)

🚀 How to Deploy (Getting Started)





Clone the Repo

git clone https://github.com/Saurabhssdr/AWS_DEVOPS_FINAL.git
cd AWS_DEVOPS_FINAL



Configure AWS CLI

aws configure

Ensure IAM user has EC2, DynamoDB, and Jenkins permissions.



Initialize Terraform

terraform init



Deploy Infrastructure

terraform apply





Provisions EC2 instance, security groups, and IAM roles.



Set Up Jenkins





Configure Jenkins with a pipeline using the provided Jenkinsfile.



Build the job to deploy the Dockerized FastAPI app.



Perform CRUD





Access Swagger UI at http://<ec2-public-ip>:8000/docs (get IP from Terraform output).



Use the interface to create, read, update, and delete DynamoDB records.

📬 Output





✅ CRUD operations functional via Swagger UI.



✅ Data stored and managed in DynamoDB.



📊 Logs available via EC2 instance (docker logs <container-id>).

🔧 Additional Notes





Ensure port 8000 is open in the EC2 security group.



Documentation: [Final DevOps+FS.pptx](Final DevOps+FS.pptx) in the repo.

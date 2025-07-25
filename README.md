📘 FastAPI CRUD Deployment on AWS

🌟 Overview
Welcome to a professionally crafted FastAPI CRUD application deployed on AWS! This project showcases a scalable solution with:

CRUD Operations stored securely in DynamoDB.
Endpoints exposed via Swagger UI on an EC2 public IP.
Automation powered by Terraform (IaC) and Jenkins.

  

🛠 Architecture Breakdown

🟢 EC2: Hosts the Dockerized FastAPI app, provisioned via Terraform.
🟡 Docker: Runs the FastAPI container with CRUD endpoints.
🔵 DynamoDB: Persists CRUD data with high availability.
🟠 Swagger UI: Enables browser-based CRUD at http://<ec2-public-ip>:8000/docs.
🟣 Terraform: Manages EC2, security groups, and IAM roles.
⚙️ Jenkins: Automates the CI/CD pipeline.
🛡️ Security Groups: Restricts access to port 8000.


🧪 Technologies Used

Amazon EC2
Amazon DynamoDB
Docker
Terraform (IaC)
Jenkins (CI/CD)


🚀 Getting Started
Prerequisites

AWS CLI configured with appropriate IAM permissions.
Git installed on your system.

Deployment Steps

Clone the Repositorygit clone https://github.com/Saurabhssdr/AWS_DEVOPS_FINAL.git
cd AWS_DEVOPS_FINAL


Configure AWS CLIaws configure


Ensure IAM user has EC2, DynamoDB, and Jenkins access.


Initialize Terraformterraform init


Deploy Infrastructureterraform apply


Deploys EC2, security groups, and IAM roles.


Set Up Jenkins
Configure with the provided Jenkinsfile.
Trigger a build to deploy the Dockerized app.


Perform CRUD Operations
Access Swagger UI at http://<ec2-public-ip>:8000/docs (IP from Terraform output).
Use the interface for create, read, update, and delete actions.




📊 Outputs

✅ Functional CRUD via Swagger UI.
✅ Data Persistence in DynamoDB.
📋 Logs accessible via docker logs <container-id> on EC2.


📝 Additional Notes

Security: Ensure port 8000 is open in the EC2 security group.
Documentation: Final DevOps+FS.pptx available in the repo for reference.


📬 Connect With Me

🌐 GitHub
💼 LinkedIn



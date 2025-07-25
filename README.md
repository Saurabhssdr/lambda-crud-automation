# 📘 Serverless FastAPI CRUD Deployment on AWS
 
## 🌟 Overview
Welcome to a professionally crafted FastAPI CRUD application deployed on AWS!  
This project showcases a scalable cloud-native solution with:
 
- 🔄 Full CRUD operations backed by DynamoDB.
- 🌐 Public API access via Swagger UI hosted on an EC2 instance.
- ⚙️ Automated provisioning with Terraform.
- 🚀 CI/CD pipeline powered by Jenkins.
 
---
 
## 🛠 Architecture Breakdown
 
- 🟢 **Amazon EC2**  
  Hosts the Dockerized FastAPI application. Provisioned using Terraform.
 
- 🟡 **Docker**  
  Runs the FastAPI container exposing CRUD endpoints.
 
- 🔵 **Amazon DynamoDB**  
  Securely stores CRUD data with high durability.
 
- 🟠 **Swagger UI**  
  Provides a browser-accessible interface for testing APIs at `http://<EC2-Public-IP>:8000/docs`.
 
- 🟣 **Terraform**  
  Automates infrastructure setup – EC2 instance, security groups, IAM roles.
 
- ⚙️ **Jenkins**  
  Manages CI/CD pipeline to deploy and update the app.
 
- 🛡️ **Security Groups**  
  Controls inbound traffic, allowing only required ports (e.g., 8000).
 
---
 
## 🧪 Technologies Used
 
- Amazon EC2  
- Amazon DynamoDB  
- Docker  
- Terraform (IaC)  
- Jenkins (CI/CD)
 
---
 
## 🚀 Getting Started
 
### 📋 Prerequisites
 
- AWS CLI configured (`aws configure`)
- Git installed
- Access credentials with permissions for EC2, IAM, and DynamoDB
 
### 🧰 Deployment Steps
 
```bash
# 1. Clone the Repository
git clone https://github.com/Saurabhssdr/lambda-crud-automation.git
cd lambda-crud-automation
 
# 2. Configure AWS CLI
aws configure
 
# 3. Initialize Terraform
terraform init
 
# 4. Apply Terraform to deploy infrastructure
terraform apply
```
 
---
 
## 📤 Outputs
 
- ✅ **FastAPI Swagger UI** accessible at `http://<EC2-Public-IP>:8000/docs`
- ✅ **CRUD operations** (Create, Read, Update, Delete) via browser interface
- ✅ **Data stored** securely in Amazon DynamoDB
- 📋 **Container logs** viewable using:
  ```bash
  docker logs <container-id>
  ```
- 🚀 **CI/CD pipeline** via Jenkins automates deployment
 
---
 
## 📝 Additional Notes
 
- 🔐 Ensure port `8000` is open in the EC2 security group
- 📂 Final DevOps presentation (`DevOps+FS.pptx`) available in the repo
- 💡 Destroy AWS resources after use to avoid charges
 
---
 
## 📬 Connect With Me
 
- 🌐 [GitHub](https://github.com/Saurabhssdr)
- 💼 [LinkedIn](https://linkedin.com/in/saurabh-daundkar)

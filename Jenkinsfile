// pipeline {

//   agent any
 
//   environment {

//     AWS_REGION = 'us-east-1'

//     AWS_ACCESS_KEY_ID = credentials('aws-access-key')

//     AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')

//   }
 
//   stages {
 
//     stage('Checkout Code') {

//       steps {

//         git branch: 'main', url: 'https://github.com/Saurabhssdr/lambda-crud-automation.git'

//       }

//     }
 
//     stage('Terraform Init') {

//       steps {

//         dir('terraform') {

//           bat 'terraform init'

//         }

//       }

//     }
 
//     stage('Terraform Plan') {

//       steps {

//         dir('terraform') {

//           bat 'terraform plan'

//         }

//       }

//     }
 
//     stage('Terraform Apply (Create EC2)') {

//       steps {

//         dir('terraform') {

//           bat 'terraform apply -auto-approve'

//         }

//       }

//     }
 
//     stage('Wait for EC2 Setup') {

//       steps {

//         echo " Waiting 3 minutes for EC2 and FastAPI setup to complete..."

//         bat 'ping -n 181 127.0.0.1 > nul' // 3-minute wait for EC2 init

//       }

//     }
 
//   }
 
//   post {

//     success {

//       echo ' EC2 instance created successfully. You can now use the public IP in the browser for CRUD.'

//     }

//     failure {

//       echo ' EC2 instance creation failed.'

//     }

//   }

// }

pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        TIMESTAMP = "${new Date().format('yyyyMMddHHmmss')}" // Sanitized timestamp (e.g., 20250731104723)
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Saurabhssdr/lambda-crud-automation.git'
                echo 'Code checked out successfully'
            }
        }
        stage('Verify Tools') {
            steps {
                bat 'terraform -v || exit /b 1'
                bat 'kubectl version --client || exit /b 1'
                bat 'eksctl version || exit /b 1'
                echo 'Tools verified successfully'
            }
        }
        stage('Initialize Terraform') {
            steps {
                dir('terraform') {
                    bat 'terraform init || exit /b 1'
                    echo 'Terraform initialized'
                }
            }
        }
        stage('Terraform Apply (Create EC2)') {
            steps {
                dir('terraform') {
                    bat """
                        terraform apply -var "role_name=ec2-dynamodb-role-${TIMESTAMP}" -var "profile_name=ec2-instance-profile-${TIMESTAMP}" -var "table_name=LocationsTerraform-${TIMESTAMP}" -auto-approve || exit /b 1
                        for /f "tokens=*" %%i in ('terraform output -raw ec2_public_ip') do set EC2_IP=%%i && echo EC2_IP=%%i > ../env.properties || exit /b 1
                    """
                    echo 'EC2 instance created'
                }
            }
        }
        stage('Wait for EC2 Setup') {
            steps {
                echo "Waiting 3 minutes for EC2 and FastAPI setup to complete..."
                bat 'ping -n 181 127.0.0.1 > nul'
            }
        }
        stage('Create EKS Cluster') {
            steps {
                bat 'eksctl create cluster --name fastapi-eks-${TIMESTAMP} --region %AWS_REGION% --nodegroup-name standard-workers --node-type t2.micro --nodes 1 --managed=false || exit /b 1'
                bat 'aws eks --region %AWS_REGION% update-kubeconfig --name fastapi-eks-${TIMESTAMP} || exit /b 1'
                echo 'EKS cluster created'
            }
        }
        stage('Configure EC2 and Join EKS') {
            steps {
                script {
                    def ec2Ip = readFile('env.properties').trim().split('=')[1]
                    bat """
                        ssh -i C:/Users/SaurabhDaundkar/my-key-pem.pem ec2-user@${ec2Ip} "sudo yum update -y && sudo yum install -y docker git kubeadm kubelet kubectl && sudo systemctl start docker && sudo systemctl enable docker && sudo usermod -aG docker ec2-user && newgrp docker" || exit /b 1
                        for /f "tokens=*" %%i in ('aws eks create-token --cluster-name fastapi-eks-${TIMESTAMP} --region %AWS_REGION% --query "status.token" --output text') do set JOIN_CMD=%%i
                        for /f "tokens=*" %%i in ('aws eks describe-cluster --name fastapi-eks-${TIMESTAMP} --region %AWS_REGION% --query "cluster.endpoint" --output text') do set ENDPOINT=%%i
                        for /f "tokens=*" %%i in ('aws eks describe-cluster --name fastapi-eks-${TIMESTAMP} --region %AWS_REGION% --query "cluster.certificateAuthority.data" --output text ^| base64 -d ^| sha256sum ^| awk "{print \$1}"') do set HASH=%%i
                        ssh -i C:/Users/SaurabhDaundkar/my-key-pem.pem ec2-user@${ec2Ip} "sudo kubeadm join --token %JOIN_CMD% %ENDPOINT% --discovery-token-ca-cert-hash sha256:%HASH%" || exit /b 1
                    """
                    echo 'EC2 joined to EKS'
                }
            }
        }
        stage('Copy Code and Build Image') {
            steps {
                script {
                    def ec2Ip = readFile('env.properties').trim().split('=')[1]
                    bat """
                        scp -i C:/Users/SaurabhDaundkar/my-key-pem.pem -r ./* ec2-user@${ec2Ip}:/home/ec2-user/lambda-crud-automation || exit /b 1
                        ssh -i C:/Users/SaurabhDaundkar/my-key-pem.pem ec2-user@${ec2Ip} "cd /home/ec2-user/lambda-crud-automation && [ -f dockerfile ] && mv dockerfile Dockerfile && docker build -t fastapi-crud . && docker stop fastapi-crud || true && docker rm fastapi-crud || true && docker run -d -p 8000:80 --restart unless-stopped --name fastapi-crud fastapi-crud" || exit /b 1
                    """
                    echo 'Image built and running on EC2'
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                bat """
                    aws eks --region %AWS_REGION% update-kubeconfig --name fastapi-eks-${TIMESTAMP} || exit /b 1
                    kubectl apply -f deployment.yaml || exit /b 1
                    kubectl apply -f service.yaml || exit /b 1
                """
                echo 'Deployed to EKS'
            }
        }
        stage('Expose and Verify') {
            steps {
                bat """
                    :loop
                    for /f "tokens=*" %%i in ('kubectl get svc fastapi-service -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" --kubeconfig=%USERPROFILE%\\.kube\\config') do set EXTERNAL_IP=%%i
                    if not defined EXTERNAL_IP (
                        echo Waiting for LoadBalancer IP...
                        timeout /t 60
                        goto loop
                    )
                    echo FastAPI accessible at http://%EXTERNAL_IP%
                """
            }
        }
    }
    post {
        always {
            dir('terraform') {
                bat 'terraform destroy -var "role_name=ec2-dynamodb-role-${TIMESTAMP}" -var "profile_name=ec2-instance-profile-${TIMESTAMP}" -var "table_name=LocationsTerraform-${TIMESTAMP}" -auto-approve || true'
            }
            bat 'eksctl delete cluster --name fastapi-eks-${TIMESTAMP} --region %AWS_REGION% --wait || true'
            echo 'Cleanup completed'
        }
    }
}

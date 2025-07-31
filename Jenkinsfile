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
    TIMESTAMP = "${new Date().format('yyyyMMddHHmmss')}"
    KEY_PATH = 'C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\lambda-crud-pipeline\\my-key-pem.pem'
    EC2_IP_FILE = 'env.properties'
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
        bat 'terraform -v'
        bat 'kubectl version --client'
        bat 'eksctl version'
        echo 'Tools verified'
      }
    }

    stage('Terraform Apply (Create EC2)') {
      steps {
        dir('terraform') {
          bat """
            terraform init
            terraform apply -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
          """
          script {
            def ip = bat(returnStdout: true, script: 'terraform output -raw ec2_public_ip').trim()
            writeFile file: EC2_IP_FILE, text: "EC2_IP=${ip}"
          }
          echo "EC2 launched, IP stored"
        }
      }
    }

    stage('Wait for SSH Ready') {
      steps {
        echo "Waiting up to 3 minutes for SSH to become available..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          timeout(time: 3, unit: 'MINUTES') {
            retry(6) {
              bat """
                ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "echo SSH OK"
              """
              sleep(time: 30, unit: 'SECONDS')
            }
          }
        }
        echo "SSH access confirmed"
      }
    }

    stage('Create EKS Cluster') {
      steps {
        bat """
          eksctl create cluster --name fastapi-eks-v%TIMESTAMP% --region %AWS_REGION% --nodegroup-name v-standard-workers-%TIMESTAMP% --node-type t2.micro --nodes 1 --managed=false
          aws eks --region %AWS_REGION% update-kubeconfig --name fastapi-eks-v%TIMESTAMP%
        """
        echo 'EKS cluster created'
      }
    }

    stage('Configure EC2 and Join EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "sudo yum update -y && sudo yum install -y docker git kubeadm kubelet kubectl && sudo systemctl enable docker && sudo systemctl start docker && sudo usermod -aG docker ec2-user"

            for /f "tokens=*" %%i in ('aws eks create-token --cluster-name fastapi-eks-v%TIMESTAMP% --region %AWS_REGION% --query "status.token" --output text') do set JOIN_CMD=%%i
            for /f "tokens=*" %%i in ('aws eks describe-cluster --name fastapi-eks-v%TIMESTAMP% --region %AWS_REGION% --query "cluster.endpoint" --output text') do set ENDPOINT=%%i
            for /f "tokens=*" %%i in ('aws eks describe-cluster --name fastapi-eks-v%TIMESTAMP% --region %AWS_REGION% --query "cluster.certificateAuthority.data" --output text ^| base64 -d ^| sha256sum') do set HASH=%%~i

            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "sudo kubeadm join --token %JOIN_CMD% %ENDPOINT% --discovery-token-ca-cert-hash sha256:%HASH%"
          """
        }
        echo 'EC2 joined to EKS'
      }
    }

    stage('Build and Deploy FastAPI') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" -r ./* ec2-user@${ec2Ip}:/home/ec2-user/lambda-crud-automation
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "cd /home/ec2-user/lambda-crud-automation && mv dockerfile Dockerfile && docker build -t fastapi-crud . && docker stop fastapi-crud || true && docker rm fastapi-crud || true && docker run -d -p 8000:80 --restart unless-stopped --name fastapi-crud fastapi-crud"
          """
        }
        echo 'Dockerized FastAPI deployed'
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        bat """
          aws eks --region %AWS_REGION% update-kubeconfig --name fastapi-eks-v%TIMESTAMP%
          kubectl apply -f deployment.yaml
          kubectl apply -f service.yaml
        """
        echo 'Deployed to EKS'
      }
    }

    stage('Verify LoadBalancer URL') {
      steps {
        bat """
          :loop
          for /f "tokens=*" %%i in ('kubectl get svc fastapi-service -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" --kubeconfig=%USERPROFILE%\\.kube\\config') do set LB=%%i
          if not defined LB (
            echo Waiting...
            timeout /t 60
            goto loop
          )
          echo FastAPI accessible at http://%LB%
        """
      }
    }
  }

  post {
    always {
      dir('terraform') {
        bat """
          terraform destroy -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
        """
      }
      bat """
        kubectl delete pod --all -n default --force --grace-period=0
        eksctl delete cluster --name fastapi-eks-v%TIMESTAMP% --region %AWS_REGION% --wait
      """
      echo 'Cleanup done'
    }
  }
}



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
        echo '✅ Code checked out'
      }
    }

    stage('Terraform Apply (Create EC2)') {
      steps {
        dir('terraform') {
          bat 'terraform init'
          bat """
            terraform apply -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
          """
          script {
            def ip = bat(returnStdout: true, script: 'terraform output -raw ec2_public_ip').trim()
            if (!ip) {
              error "❌ Terraform output for EC2 public IP is empty!"
            }
            writeFile file: EC2_IP_FILE, text: "EC2_IP=${ip}"
            echo "✅ EC2 Public IP stored in ${EC2_IP_FILE}: ${ip}"
          }
        }
      }
    }

    stage('Validate env.properties') {
      steps {
        script {
          if (!fileExists(EC2_IP_FILE)) {
            error "❌ env.properties file not found!"
          }
          def content = readFile(EC2_IP_FILE).trim()
          if (!content || !content.contains('=')) {
            error "❌ env.properties file is empty or malformed! Content: ${content}"
          }
          echo "✅ env.properties validated: ${content}"
        }
      }
    }

    stage('Wait for SSH Ready') {
      steps {
        echo "⏳ Waiting 3 minutes for EC2 SSH to be ready... (Manual verification required)"
        bat 'ping -n 181 127.0.0.1 > nul'
        script {
          def ec2IpLine = readFile(EC2_IP_FILE).trim()
          def parts = ec2IpLine.split('=')
          if (parts.length < 2) {
            error "❌ Invalid env.properties format: ${ec2IpLine}"
          }
          def ec2Ip = parts[1].trim()
          if (!ec2Ip) {
            error "❌ EC2 IP is empty in env.properties"
          }
          echo "🔍 Please manually verify SSH to ${ec2Ip} with: ssh -i ${KEY_PATH} ec2-user@${ec2Ip}"
        }
        input 'Confirm SSH to EC2 is working and ready to proceed?'
        echo '✅ EC2 verified and ready for EKS join'
      }
    }

    stage('Create EKS Cluster') {
      steps {
        bat """
          eksctl create cluster --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION} --nodes 2 --managed --node-type t2.micro --with-oidc --ssh-access --ssh-public-key my-key-pem
        """
        echo "✅ EKS cluster created: fastapi-eks-v${TIMESTAMP}"
      }
    }

    stage('Configure EC2 to Use EKS') {
      steps {
        script {
          def ec2IpLine = readFile(EC2_IP_FILE).trim()
          def parts = ec2IpLine.split('=')
          def ec2Ip = parts[1].trim()
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\lambda-crud-pipeline\\deployment.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\lambda-crud-pipeline\\service.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "aws eks update-kubeconfig --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION}"
          """
          echo "✅ EC2 configured with EKS kubeconfig"
        }
      }
    }

    stage('Deploy FastAPI to EKS') {
      steps {
        script {
          def ec2IpLine = readFile(EC2_IP_FILE).trim()
          def parts = ec2IpLine.split('=')
          def ec2Ip = parts[1].trim()
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f deployment.yaml"
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f service.yaml"
          """
          echo "✅ FastAPI deployed to EKS cluster"
        }
      }
    }

    stage('Get Load Balancer URL') {
      steps {
        script {
          def ec2IpLine = readFile(EC2_IP_FILE).trim()
          def parts = ec2IpLine.split('=')
          def ec2Ip = parts[1].trim()
          def lbUrl = bat(returnStdout: true, script: """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl get svc fastapi-service --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
          """).trim()
          echo "🌐 Load Balancer URL: http://${lbUrl}"
        }
      }
    }
  }

  post {
    success {
      echo '✅ Cleaning up resources...'
      dir('terraform') {
        bat """
          terraform destroy -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
        """
      }
      bat """
        kubectl delete pod --all -n default --force --grace-period=0
        eksctl delete cluster --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION} --wait
      """
      echo "✅ Cleanup completed"
    }
    failure {
      echo '❌ Pipeline failed. Please check logs and do manual cleanup if necessary.'
    }
  }
}

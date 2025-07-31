pipeline {
  agent any

  environment {
    AWS_REGION = 'us-east-1'
    AWS_ACCESS_KEY_ID = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    TIMESTAMP = "${new Date().format('yyyyMMddHHmmss')}"
    KEY_PATH = 'C:/ProgramData/Jenkins/.jenkins/workspace/lambda-crud-pipeline/my-key-pem.pem'
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
            // Get EC2 IP locally from terraform output
            def ip = bat(returnStdout: true, script: 'terraform output -raw ec2_public_ip').trim()
            echo "🌐 Terraform EC2 Public IP: '${ip}'"
            if (!ip || ip == '' || ip == 'null') {
              error "❌ Terraform output for EC2 public IP is empty or invalid."
            }
            // Save to file for later stages
            writeFile file: EC2_IP_FILE, text: "EC2_IP=${ip}"
            echo "✅ Saved EC2 IP to ${EC2_IP_FILE}"
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
          echo "📄 env.properties content: '${content}'"
          if (!content || !content.contains('=')) {
            error "❌ env.properties is empty or malformed!"
          }
          echo "✅ env.properties validated successfully"
        }
      }
    }

    stage('Wait for SSH Ready') {
      steps {
        echo "⏳ Waiting 3 minutes for EC2 SSH readiness (manual check)..."
        bat 'ping -n 181 127.0.0.1 > nul'  // 3 minutes delay
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          echo "🔍 Please manually verify SSH connection: ssh -i ${KEY_PATH} ec2-user@${ec2Ip}"
        }
        input 'Confirm SSH to EC2 is working?'
      }
    }

    stage('Test SSH Connection') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          echo "🔌 Testing SSH connection to ${ec2Ip}..."
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "echo SSH connection successful"
          """
        }
      }
    }

    stage('Create EKS Cluster') {
      steps {
        bat """
          eksctl create cluster --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION} --nodes 2 --managed --node-type t2.micro --with-oidc --ssh-access --ssh-public-key my-key-pem
        """
        echo "✅ EKS cluster created"
      }
    }

    stage('Configure EC2 for EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" deployment.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" service.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "aws eks update-kubeconfig --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION}"
          """
          echo "✅ EC2 configured with EKS kubeconfig"
        }
      }
    }

    stage('Deploy FastAPI to EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f deployment.yaml"
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f service.yaml"
          """
          echo "✅ FastAPI deployed to EKS"
        }
      }
    }

    stage('Get Load Balancer URL') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          def lbUrl = bat(returnStdout: true, script: """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl get svc fastapi-service --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
          """).trim()
          echo "🌐 FastAPI Load Balancer URL: http://${lbUrl}"
        }
      }
    }
  }

  post {
    success {
      echo '🎉 Pipeline completed. Cleaning up resources...'
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
      echo '❌ Pipeline failed. Check logs and perform manual cleanup if needed.'
    }
  }
}

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
            echo "✅ EC2 IP saved: ${ip}"
          }
        }
      }
    }

    stage('Validate env.properties') {
      steps {
        script {
          if (!fileExists(EC2_IP_FILE)) {
            error "❌ env.properties not found!"
          }
          def content = readFile(EC2_IP_FILE).trim()
          if (!content.contains("=")) {
            error "❌ env.properties malformed: ${content}"
          }
          def ip = content.split("=")[1].trim()
          if (!ip.matches("\\d+\\.\\d+\\.\\d+\\.\\d+")) {
            error "❌ Invalid IP in env.properties: ${ip}"
          }
          echo "✅ env.properties validated: ${ip}"
        }
      }
    }

    stage('Wait for SSH (Auto)') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          echo "⏳ Waiting 90 seconds for EC2 to be ready at ${ec2Ip}..."
          sleep(time: 90, unit: 'SECONDS')

          echo "🔍 Checking SSH connection..."
          def result = bat(script: "ssh -o StrictHostKeyChecking=no -i \"${KEY_PATH}\" ec2-user@${ec2Ip} \"echo SSH_OK\"", returnStatus: true)
          if (result != 0) {
            error "❌ SSH to EC2 (${ec2Ip}) failed! Make sure the key and security group are correct."
          }
          echo "✅ SSH to EC2 is working!"
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

    stage('Configure EC2 to Use EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" deployment.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" service.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "aws eks update-kubeconfig --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION}"
          """
          echo "✅ EC2 configured to access EKS"
        }
      }
    }

    stage('Deploy FastAPI to EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f deployment.yaml"
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f service.yaml"
          """
          echo "✅ FastAPI deployed"
        }
      }
    }

    stage('Get Load Balancer URL') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
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
      echo '✅ Pipeline success'
    }
    failure {
      echo '❌ Pipeline failed. Manual cleanup may be required.'
    }
  }
}

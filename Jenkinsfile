pipeline {
  agent any
  environment {
    AWS_REGION = 'us-east-1'
    AWS_ACCESS_KEY_ID = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    TIMESTAMP = "${new Date().format('yyyyMMddHHmmss')}"
    KEY_PATH = 'C:\\Users\\SaurabhDaundkar\\.ssh\\my-key.pem' // Using original key location
    EC2_IP_FILE = 'env.properties'
  }
  stages {
    stage('Checkout Code') {
      steps {
        echo "🔍 Starting code checkout from Git..."
        git branch: 'main', url: 'https://github.com/Saurabhssdr/lambda-crud-automation.git'
        echo "✅ Code checked out successfully"
      }
    }
    stage('Prepare Environment') {
      steps {
        echo "🔍 Verifying Jenkins environment..."
        bat 'dir'
        echo "✅ Environment verified"
      }
    }
    stage('Terraform Initialize') {
      steps {
        echo "🔍 Initializing Terraform in terraform directory..."
        dir('terraform') {
          bat 'terraform init'
        }
        echo "✅ Terraform initialized"
      }
    }
    stage('Terraform Apply (Create EC2)') {
      steps {
        echo "🔍 Applying Terraform configuration..."
        dir('terraform') {
          bat """
            terraform apply -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
          """
          script {
            echo "🔍 Extracting EC2 public IP from Terraform output..."
            def rawOutput = bat(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
            echo "🔍 Raw Terraform output:\n${rawOutput}"
            def lines = rawOutput.readLines()
            def ipLine = lines[-1].trim()
            if (!ipLine.matches("\\d+\\.\\d+\\.\\d+\\.\\d+")) {
              error "❌ No valid IP found in terraform output. Got:\n${ipLine}"
            }
            writeFile file: "../${EC2_IP_FILE}", text: "EC2_IP=${ipLine}"
            echo "✅ EC2 Public IP saved to ${EC2_IP_FILE}: ${ipLine}"
          }
        }
      }
    }
    stage('Validate env.properties') {
      steps {
        echo "🔍 Validating env.properties file..."
        script {
          if (!fileExists(EC2_IP_FILE)) {
            error "❌ env.properties not found in root workspace!"
          }
          def content = readFile(EC2_IP_FILE).trim()
          echo "🔍 Content of env.properties:\n${content}"
          if (!content.contains('=')) {
            error "❌ env.properties malformed!"
          }
          def ip = content.split("=")[1].trim()
          if (!ip.matches("\\d+\\.\\d+\\.\\d+\\.\\d+")) {
            error "❌ Invalid IP in env.properties: ${ip}"
          }
          echo "✅ Valid EC2 IP: ${ip}"
        }
      }
    }
    stage('Check Key Accessibility') {
      steps {
        echo "🔍 Checking accessibility of SSH key at ${KEY_PATH}..."
        script {
          def keyExists = bat(returnStatus: true, script: "if exist \"${KEY_PATH}\" exit 0 else exit 1")
          if (keyExists != 0) {
            error "❌ SSH key file not found at ${KEY_PATH}"
          }
          bat """
            icacls "${KEY_PATH}" /grant "SYSTEM:R" /grant "Users:R"
            icacls "${KEY_PATH}" /inheritance:r
            icacls "${KEY_PATH}" /grant:r "SaurabhDaundkar:F"
          """
          echo "✅ SSH key permissions set successfully"
        }
      }
    }
    stage('Wait for EC2 Instance') {
      steps {
        echo "🔍 Waiting 90 seconds for EC2 instance to boot..."
        sleep(time: 90, unit: 'SECONDS')
        echo "✅ EC2 boot wait completed"
      }
    }
    stage('Test SSH Connectivity') {
      steps {
        echo "🔍 Testing SSH connectivity to EC2..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          timeout(time: 5, unit: 'MINUTES') {
            retry(10) {
              sleep(time: 30, unit: 'SECONDS')
              def result = bat(returnStatus: true, script: "ssh -o StrictHostKeyChecking=no -i \"${KEY_PATH}\" ec2-user@${ec2Ip} \"echo SSH_OK\"")
              if (result != 0) {
                echo "⚠️ SSH attempt failed. Retrying... (Status: ${result})"
                sleep(time: 30, unit: 'SECONDS') // Extra delay before retry
              } else {
                echo "✅ SSH connection successful!"
              }
            }
          }
        }
      }
    }
    stage('Create EKS Cluster') {
      steps {
        echo "🔍 Creating EKS cluster..."
        bat """
          eksctl create cluster --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION} --nodes 2 --managed --node-type t2.micro --with-oidc --ssh-access --ssh-public-key my-key-pem
        """
        echo "✅ EKS cluster created"
      }
    }
    stage('Copy Configuration Files to EC2') {
      steps {
        echo "🔍 Copying deployment and service files to EC2..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" deployment.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" service.yaml ec2-user@${ec2Ip}:/home/ec2-user/
          """
          echo "✅ Files copied to EC2"
        }
      }
    }
    stage('Configure EC2 for EKS') {
      steps {
        echo "🔍 Configuring EC2 with EKS kubeconfig..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "aws eks update-kubeconfig --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION}"
          """
          echo "✅ EC2 configured with EKS"
        }
      }
    }
    stage('Deploy FastAPI to EKS') {
      steps {
        echo "🔍 Deploying FastAPI to EKS..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f deployment.yaml"
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f service.yaml"
          """
          echo "✅ FastAPI deployed to EKS"
        }
      }
    }
    stage('Verify EKS Deployment') {
      steps {
        echo "🔍 Verifying EKS deployment status..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          def deployStatus = bat(returnStdout: true, script: """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl get deployments"
          """).trim()
          echo "🔍 Deployment status:\n${deployStatus}"
          def svcStatus = bat(returnStdout: true, script: """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl get services"
          """).trim()
          echo "🔍 Service status:\n${svcStatus}"
          if (!svcStatus.contains('fastapi-service')) {
            error "❌ fastapi-service not found in EKS"
          }
          echo "✅ EKS deployment verified"
        }
      }
    }
    stage('Get Load Balancer URL') {
      steps {
        echo "🔍 Retrieving Load Balancer URL..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          def lbUrl = bat(returnStdout: true, script: """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl get svc fastapi-service --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
          """).trim()
          echo "🌐 Load Balancer URL: http://${lbUrl}"
          if (!lbUrl.matches("\\w+\\.\\w+\\.\\w+")) {
            error "❌ Invalid Load Balancer URL: ${lbUrl}"
          }
          echo "✅ Load Balancer URL retrieved"
        }
      }
    }
  }
  post {
    success {
      echo '✅ Deployment Successful'
    }
    failure {
      echo '❌ Pipeline failed. Check above logs for the failing stage.'
    }
  }
}

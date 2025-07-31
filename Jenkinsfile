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
            echo "🌐 EC2 Public IP from Terraform: '${ip}'"
            if (!ip || ip == '' || ip == 'null') {
              error "❌ Terraform output for EC2 public IP is empty or null! Check Terraform or AWS."
            }
            writeFile file: EC2_IP_FILE, text: "EC2_IP=${ip}"
            echo "✅ Wrote EC2 IP to env.properties: ${ip}"
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
            error "❌ env.properties is empty or malformed: '${content}'"
          }
          echo "✅ env.properties is valid"
        }
      }
    }

    stage('Wait for SSH Ready') {
      steps {
        echo "⏳ Waiting 3 minutes for EC2 to be SSH ready..."
        bat 'ping -n 181 127.0.0.1 > nul'
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          echo "🔍 Please manually verify: ssh -i ${KEY_PATH} ec2-user@${ec2Ip}"
        }
        input '✅ Confirm EC2 SSH is working. Continue?'
      }
    }

    stage('Create EKS Cluster') {
      steps {
        bat """
          eksctl create cluster --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION} --nodes 2 --managed --node-type t2.micro --with-oidc --ssh-access --ssh-public-key my-key-pem
        """
      }
    }

    stage('Configure EC2 for EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1].trim()
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" deployment.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" service.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "aws eks update-kubeconfig --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION}"
          """
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
          echo "🌐 FastAPI Load Balancer URL: http://${lbUrl}"
        }
      }
    }
  }

  post {
    success {
      echo '🎉 Pipeline completed successfully. Cleaning up...'
      dir('terraform') {
        bat """
          terraform destroy -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
        """
      }
    }
    failure {
      echo '❌ Pipeline failed. Please check logs and do manual cleanup if needed.'
    }
  }
}

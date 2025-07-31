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
            writeFile file: EC2_IP_FILE, text: "EC2_IP=${ip}"
            echo "✅ EC2 Public IP stored: ${ip}"
          }
        }
      }
    }

    stage('Wait for SSH Ready') {
      steps {
        echo "⏳ Waiting for EC2 SSH to be ready..."
        script {
          def ec2IpLine = readFile(EC2_IP_FILE).trim()
          if (!ec2IpLine.contains('=')) {
            error "❌ Invalid env.properties format: ${ec2IpLine}"
          }

          def ec2Ip = ec2IpLine.split('=')[1].trim()
          if (ec2Ip == null || ec2Ip == '') {
            error "❌ EC2 IP is empty in env.properties"
          }

          echo "🔍 Trying SSH to EC2 IP: ${ec2Ip}"
          timeout(time: 5, unit: 'MINUTES') {
            retry(10) {
              sleep(time: 30, unit: 'SECONDS')
              bat """
                ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "echo SSH OK"
              """
            }
          }
        }
      }
    }

    stage('Create EKS Cluster') {
      steps {
        bat """
          eksctl create cluster --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION} --nodes 2 --managed --node-type t2.micro --with-oidc --ssh-access --ssh-public-key my-key-pem
        """
      }
    }

    stage('Configure EC2 to Use EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\lambda-crud-pipeline\\kube-deploy.yaml ec2-user@${ec2Ip}:/home/ec2-user/
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "aws eks update-kubeconfig --name fastapi-eks-v${TIMESTAMP} --region ${AWS_REGION}"
          """
        }
      }
    }

    stage('Deploy FastAPI to EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "kubectl apply -f kube-deploy.yaml"
          """
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
    }
    failure {
      echo '❌ Pipeline failed. Manual cleanup may be required.'
    }
  }
}

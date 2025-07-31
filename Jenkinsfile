pipeline {
  agent any
  environment {
    AWS_REGION = 'us-east-1'
    AWS_ACCESS_KEY_ID = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    TIMESTAMP = "${new Date().format('yyyyMMddHHmmss')}"
    KEY_PATH = 'C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\lambda-crud-pipeline\\my-key-pem.pem'
    EC2_IP_FILE = 'env.properties'
    CLUSTER_NAME = "fastapi-eks-v${new Date().format('yyyyMMddHHmmss')}"
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
          bat """
            terraform init
            terraform apply -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
          """
          script {
            def ip = bat(returnStdout: true, script: 'terraform output -raw ec2_public_ip').trim()
            writeFile file: EC2_IP_FILE, text: "EC2_IP=${ip}"
            echo "🟢 EC2 Public IP: ${ip}"
          }
        }
      }
    }

    stage('Wait for SSH Ready') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          echo "⏳ Waiting for EC2 at ${ec2Ip} to allow SSH..."
          sleep(time: 90, unit: 'SECONDS')
          retry(5) {
            sleep(time: 15, unit: 'SECONDS')
            bat """
              ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "echo SSH OK"
            """
          }
        }
      }
    }

    stage('Create EKS Cluster') {
      steps {
        bat """
          eksctl create cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --nodegroup-name workers-${TIMESTAMP} --node-type t2.micro --nodes 1 --managed=false
          aws eks --region ${AWS_REGION} update-kubeconfig --name ${CLUSTER_NAME}
        """
        echo "✅ EKS cluster created: ${CLUSTER_NAME}"
      }
    }

    stage('Configure EC2 and Join EKS') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "
              sudo yum update -y &&
              sudo yum install -y docker git kubelet kubeadm kubectl &&
              sudo systemctl enable docker &&
              sudo systemctl start docker &&
              sudo usermod -aG docker ec2-user
            "
          """
          echo "🔧 EC2 configured with Docker and Kubernetes tools"
        }
      }
    }

    stage('Deploy FastAPI to EC2') {
      steps {
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
          bat """
            scp -o StrictHostKeyChecking=no -i "${KEY_PATH}" -r ./* ec2-user@${ec2Ip}:/home/ec2-user/lambda-crud-automation
            ssh -o StrictHostKeyChecking=no -i "${KEY_PATH}" ec2-user@${ec2Ip} "
              cd /home/ec2-user/lambda-crud-automation &&
              mv dockerfile Dockerfile &&
              docker build -t fastapi-crud . &&
              docker stop fastapi-crud || true &&
              docker rm fastapi-crud || true &&
              docker run -d -p 8000:80 --restart unless-stopped --name fastapi-crud fastapi-crud
            "
          """
          echo "🚀 FastAPI running in Docker on EC2"
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        bat """
          aws eks --region ${AWS_REGION} update-kubeconfig --name ${CLUSTER_NAME}
          kubectl apply -f deployment.yaml
          kubectl apply -f service.yaml
        """
        echo "📦 FastAPI deployed to EKS"
      }
    }

    stage('Get LoadBalancer URL') {
      steps {
        script {
          retry(5) {
            bat """
              kubectl get svc fastapi-service -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
            """
            sleep(time: 30, unit: 'SECONDS')
          }
        }
      }
    }
  }

  post {
    success {
      echo '✅ Pipeline complete'

      // Keep cleanup disabled for now to debug easily
      // Uncomment later to auto-clean
      // dir('terraform') {
      //   bat """
      //     terraform destroy -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
      //   """
      // }
      // bat """
      //   kubectl delete pod --all -n default --force --grace-period=0
      //   eksctl delete cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --wait
      // """
    }

    failure {
      echo '❌ Pipeline failed — keeping resources for debugging.'
    }
  }
}

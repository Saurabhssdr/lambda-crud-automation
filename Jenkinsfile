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
        }
      }
    }

    stage('Wait for SSH Ready') {
      steps {
        echo "Waiting for EC2 to be ready for SSH..."
        script {
          def ec2Ip = readFile(EC2_IP_FILE).trim().split('=')[1]
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

    // ✅ Add rest of your existing stages here, no changes needed to logic
    // Like: Create EKS, Deploy FastAPI, etc.

  }

  post {
    success {
      echo 'Cleaning up resources on success'
      dir('terraform') {
        bat """
          terraform destroy -var "role_name=ec2-dynamodb-role" -var "profile_name=ec2-instance-profile" -var "table_name=LocationsTerraform" -var "sg_name=allow_http" -var "timestamp=${TIMESTAMP}" -auto-approve
        """
      }
      bat """
        kubectl delete pod --all -n default --force --grace-period=0
        eksctl delete cluster --name fastapi-eks-v%TIMESTAMP% --region %AWS_REGION% --wait
      """
    }
    failure {
      echo 'Pipeline failed. Skipping destroy to allow manual debugging.'
    }
  }
}

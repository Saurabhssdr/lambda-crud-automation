pipeline {

  agent any
 
  environment {

    AWS_REGION = 'us-east-1'

    AWS_ACCESS_KEY_ID = credentials('aws-access-key')

    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')

  }
 
  stages {

    stage('Checkout Code') {

      steps {

        git branch: 'main', url: 'https://github.com/Saurabhssdr/lambda-crud-automation.git'

      }

    }
 
    stage('Terraform Init') {

      steps {

        dir('terraform') {

          bat 'terraform init'

        }

      }

    }
 
    stage('Terraform Plan') {

      steps {

        dir('terraform') {

          bat 'terraform plan'

        }

      }

    }
 
    stage('Terraform Apply (Create EC2)') {

      steps {

        dir('terraform') {

          bat 'terraform apply -auto-approve'

        }

      }

    }
 
    stage('Wait for EC2 Setup') {

      steps {

        echo "⏳ Waiting 3 minutes for EC2 and FastAPI setup to complete..."

        bat 'sleep 180'

      }

    }
 
    stage('Show EC2 Public IP') {

      steps {

        dir('terraform') {

          bat 'terraform output fastapi_public_ip'

        }

      }

    }

  }
 
  post {

    success {

      echo '✅ EC2 instance created successfully. You can now use the public IP in the browser for CRUD.'

    }

    failure {

      echo '❌ EC2 instance creation failed.'

    }

  }

}

 

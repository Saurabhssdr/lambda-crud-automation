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

          sh 'terraform init'

        }

      }

    }
 
    stage('Terraform Apply - EC2 Only') {

      steps {

        dir('terraform') {

          sh 'terraform apply -auto-approve'

        }

      }

    }
 
    stage('Wait for EC2 Setup') {

      steps {

        echo "⏳ Waiting for EC2 and FastAPI to initialize (3 mins)..."

        sh 'sleep 180'

      }

    }

  }
 
  post {

    success {

      echo '✅ EC2 instance created and setup.sh executed.'

    }

    failure {

      echo '❌ EC2 creation failed.'

    }

  }

}

 
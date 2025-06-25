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
 
        stage('Terraform Apply') {

            steps {

                dir('terraform') {

                    bat 'terraform apply -auto-approve'

                }

            }

        }
 
        stage('Read Lambda Name from Output') {

            steps {

                dir('terraform') {

                    bat 'terraform output -raw lambda_function_name > lambda_name.txt'

                }

            }

        }
 
        stage('Invoke Lambda Function') {

            steps {

                script {

                    def functionName = readFile('terraform/lambda_name.txt').trim()

                    echo "Invoking Lambda: ${functionName}"

                    // Fixed line here

                    bat "aws lambda invoke --function-name ${functionName} --region %AWS_REGION% --payload \"{}\" lambda_output.json"

                    bat "type lambda_output.json"

                }

            }

        }

    }
 
    post {

        success {

            echo '✅ Deployment and test successful!'

        }

        failure {

            echo '❌ Deployment or test failed.'

        }

    }

}


 

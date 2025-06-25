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

                    bat "aws lambda invoke --function-name ${functionName} --region %AWS_REGION% --payload \"{}\" lambda_output.json"

                    bat "type lambda_output.json"

                }

            }

        }
 
        stage('Print EC2 Public IP') {

            steps {

                dir('terraform') {

                    echo "Fetching EC2 Public IP..."

                    bat 'terraform output -raw ec2_public_ip > ec2_ip.txt'

                    script {

                        def ec2Ip = readFile('terraform/ec2_ip.txt').trim()

                        echo "🌐 FastAPI App running at: http://${ec2Ip}"

                    }

                }

            }

        }

    }
 
    post {

        success {

            echo '✅ All resources deployed and Lambda tested successfully!'

        }

        failure {

            echo '❌ Deployment or testing failed.'

        }

    }

}

 
 

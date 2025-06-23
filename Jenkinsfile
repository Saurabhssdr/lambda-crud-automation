pipeline {

    agent any
 
    environment {

        AWS_REGION = 'us-east-1'

    }
 
    stages {

        stage('Checkout Code') {

            steps {

                git branch: 'main', url: 'https://github.com/Saurabhssdr/lambda-crud-automation.git'

            }

        }
 
        stage('Set Up Terraform') {

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
 
        stage('Deploy Lambda (Terraform Apply)') {

            steps {

                dir('terraform') {

                    bat 'terraform apply -auto-approve'

                }

            }

        }
 
        stage('Invoke Lambda (Test Run)') {

            steps {

                dir('terraform') {

                    script {

                        // Save lambda function name to a file

                        bat 'terraform output -raw lambda_function_name > lambda_name.txt'
 
                        // Read it from the file

                        def functionName = readFile('lambda_name.txt').trim()

                        echo "Running Lambda Function: ${functionName}"
 
                        // Invoke Lambda function

                        bat """

                        aws lambda invoke ^

                          --function-name ${functionName} ^

                          --region %AWS_REGION% ^

                          --payload "{}" ^

                          lambda_output.json

                        """
 
                        // Print the Lambda response

                        bat 'type lambda_output.json'

                    }

                }

            }

        }

    }
 
    post {

        success {

            echo '✅ Deployment and Lambda test successful!'

        }

        failure {

            echo '❌ Deployment or test failed. Check the logs.'

        }

    }

}

 

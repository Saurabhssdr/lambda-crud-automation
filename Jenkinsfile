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
 
        stage('Invoke Lambda (Optional Test Run)') {

            steps {

                script {

                    def functionName = bat(

                        script: 'terraform -chdir=terraform output -raw lambda_function_name',

                        returnStdout: true

                    ).trim()
 
                    echo "Running Lambda function: ${functionName}"
 
                    bat """

                        aws lambda invoke ^

                          --function-name ${functionName} ^

                          --region ${env.AWS_REGION} ^

                          --payload "{}" ^

                          lambda_output.json

                    """

                    bat 'type lambda_output.json'

                }

            }

        }

    }
 
    post {

        success {

            echo '✅ Deployment successful!'

        }

        failure {

            echo '❌ Deployment failed.'

        }

    }

}

 

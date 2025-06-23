resource "aws_lambda_function" "test_crud_lambda" {

  function_name = "TestCRUDAutomation"

  role          = aws_iam_role.lambda_exec.arn

  handler       = "lambda_function.lambda_handler"

  runtime       = "python3.11"
 
  filename         = "../lambda/lambda_function.zip"

  source_code_hash = filebase64sha256("../lambda/lambda_function.zip")

  timeout = 120
 
  environment {

    variables = {

      FASTAPI_URL = "http://54.163.37.68:8001/locations"

    }

  }

}

 

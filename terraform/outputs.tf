output "lambda_function_name" {
  value = aws_lambda_function.test_crud_lambda.function_name
}
 
output "lambda_function_arn" {
  value = aws_lambda_function.test_crud_lambda.arn
}
 
output "iam_role_name" {
  value = aws_iam_role.lambda_exec.name
}
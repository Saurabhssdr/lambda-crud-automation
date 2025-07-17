provider "aws" {
  region = "us-east-1"
}
 
# 1. IAM Role for EC2 to access DynamoDB
resource "aws_iam_role" "ec2_dynamo_role-v10" {
  name = "ec2-dynamo-role-v10"
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
 
# 2. Attach AmazonDynamoDBFullAccess policy to that role
resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.ec2_dynamo_role-v10.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
 
# 3. Create an instance profile from that role
resource "aws_iam_instance_profile" "ec2_profile-v10" {
  name = "ec2-instance-profile-v10"
  role = aws_iam_role.ec2_dynamo_role-v10.name
}
 
# 4. Create EC2 instance and attach role
resource "aws_instance" "fastapi_ec2" {
  ami                    = "ami-051f8a213df8bc089"  # Amazon Linux 2 (check latest for your region)
  instance_type          = "t2.micro"
  key_name               = "my-key-pem"             # Replace with your key
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile-v10.name
  user_data              = file("${path.module}/setup.sh")
 
  tags = {
    Name = "fastapi-instance"
  }
}

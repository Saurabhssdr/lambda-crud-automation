provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ec2_dynamodb_role19" {
  name = "ec2-dynamodb-role19"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.ec2_dynamodb_role19.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile2" {
  name = "ec2-instance-profile2"
  role = aws_iam_role.ec2_dynamodb_role19.name
}

resource "aws_dynamodb_table" "locations_table" {
  name           = "Locations_resource"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "country"
  range_key      = "city_id"
  attribute {
    name = "country"
    type = "S"
  }
  attribute {
    name = "city_id"
    type = "S"
  }
  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "fastapi_ec2" {
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  key_name               = "my-key-pem" // Using your existing key pair
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile2.name
  user_data              = file("${path.module}/setup.sh")
  vpc_security_group_ids = [aws_security_group.allow_http.id]

  tags = {
    Name = "fastapi-instance"
  }
}

output "ec2_public_ip" {
  value = aws_instance.fastapi_ec2.public_ip
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "fastapi_ec2" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  user_data     = file("${path.module}/setup.sh")  # Correct relative path
  tags = {
    Name = "FastAPI-EC2"
  }
 
  vpc_security_group_ids = [aws_security_group.allow_http.id]
}

 
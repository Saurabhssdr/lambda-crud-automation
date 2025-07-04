resource "aws_instance" "fastapi_ec2" {
  ami           = "ami-051f8a213df8bc089"  
  instance_type = "t2.micro"
  key_name      = "my-key-pem"        
  user_data     = file("${path.module}/setup.sh")
 
  tags = {
    Name = "fastapi-instance"
  }
}
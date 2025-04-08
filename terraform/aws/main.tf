provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (update as needed)
  instance_type = "t2.micro"
  key_name      = "paper-social-key"      # Replace with your key pair name

  tags = {
    Name = "paper-social-web"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

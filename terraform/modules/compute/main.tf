resource "aws_instance" "compute" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "paper-social-key"

  tags = {
    Name = "paper-social-compute"
  }
}

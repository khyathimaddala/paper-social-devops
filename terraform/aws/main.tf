provider "aws" {
  region = "us-east-1"
}

# Existing Security Group for Instances (ports 22 and 5000)
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_sg"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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

# Existing EC2 Instances
resource "aws_instance" "web" {
  ami                    = "ami-01f5a0b78d6089704"
  instance_type          = "t2.micro"
  key_name               = "paper-social-key"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "paper-social-web"
  }
}

resource "aws_instance" "paper-social-web-2" {
  ami                    = "ami-01f5a0b78d6089704"
  instance_type          = "t2.micro"
  key_name               = "paper-social-key"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "paper-social-web-2"
  }
}

# New Security Group for ALB (port 80)
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP inbound traffic"

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

# ALB
resource "aws_lb" "paper-social-alb" {
  name               = "paper-social-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnets.available.ids[0], data.aws_subnets.available.ids[1]]

  enable_deletion_protection = false
}

# Data Source for Available Subnets
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data Source for Default VPC
data "aws_vpc" "default" {
  default = true
}

# Target Group
resource "aws_lb_target_group" "paper-social-tg" {
  name     = "paper-social-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path = "/"
    port = 5000
    protocol = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

# Attach Instances to Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  target_group_arn = aws_lb_target_group.paper-social-tg.arn
  target_id        = aws_instance.web.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "web2_attachment" {
  target_group_arn = aws_lb_target_group.paper-social-tg.arn
  target_id        = aws_instance.paper-social-web-2.id
  port             = 5000
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.paper-social-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.paper-social-tg.arn
  }
}

# Outputs
output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "instance_public_ip_2" {
  value = aws_instance.paper-social-web-2.public_ip
}

output "alb_dns_name" {
  value = aws_lb.paper-social-alb.dns_name
}

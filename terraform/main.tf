data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "taskops" {
  name        = "prajwal-taskops-sg"
  description = "TaskOps: allow only HTTP, HTTPS and SSH"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (restricted to the admin IP)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Prajwal-Ganorkar-TaskOps-sg"
  }
}

resource "aws_instance" "taskops" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.taskops.id]
  user_data              = file("${path.module}/user_data.sh")

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    encrypted   = true
    volume_size = 12
    volume_type = "gp3"
  }

  tags = {
    Name = "Prajwal-Ganorkar-TaskOps"
  }
}

# Stable public IP so the deployed URL does not change after a stop/start.
resource "aws_eip" "taskops" {
  instance = aws_instance.taskops.id
  domain   = "vpc"

  tags = {
    Name = "Prajwal-Ganorkar-TaskOps-eip"
  }
}

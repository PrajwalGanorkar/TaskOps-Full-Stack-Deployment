variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Name of an existing EC2 key pair"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Your public IP in CIDR form, e.g. 203.0.113.4/32 (SSH is only opened to this range)"
}

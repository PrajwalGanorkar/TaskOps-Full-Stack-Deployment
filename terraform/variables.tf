variable "aws_region" { type=string; default="ap-south-1" }
variable "instance_type" { type=string; default="t3.micro" }
variable "key_name" { type=string; description="Existing EC2 key pair name" }
variable "allowed_ssh_cidr" { type=string; description="Your public IP in CIDR format, e.g. 1.2.3.4/32" }

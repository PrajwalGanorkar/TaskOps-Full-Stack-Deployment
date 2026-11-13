data "aws_ami" "ubuntu" {
 most_recent=true; owners=["099720109477"]
 filter { name="name"; values=["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
}
resource "aws_security_group" "taskops" {
 name="prajwal-taskops-sg"
 ingress { from_port=80; to_port=80; protocol="tcp"; cidr_blocks=["0.0.0.0/0"] }
 ingress { from_port=22; to_port=22; protocol="tcp"; cidr_blocks=[var.allowed_ssh_cidr] }
 egress { from_port=0; to_port=0; protocol="-1"; cidr_blocks=["0.0.0.0/0"] }
}
resource "aws_instance" "taskops" {
 ami=data.aws_ami.ubuntu.id
 instance_type=var.instance_type
 key_name=var.key_name
 vpc_security_group_ids=[aws_security_group.taskops.id]
 user_data= file("${path.module}/user_data.sh")
 root_block_device { encrypted=true; volume_size=12; volume_type="gp3" }
 tags={Name="Prajwal-Ganorkar-TaskOps"}
}

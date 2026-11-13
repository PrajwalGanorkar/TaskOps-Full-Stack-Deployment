output "public_ip" {
  value = aws_eip.taskops.public_ip
}

output "application_url" {
  value = "http://${aws_eip.taskops.public_ip}"
}

output "ssh_command" {
  value = "ssh -i <your-key>.pem ubuntu@${aws_eip.taskops.public_ip}"
}

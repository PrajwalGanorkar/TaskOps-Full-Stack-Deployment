output "public_ip" { value=aws_instance.taskops.public_ip }
output "application_url" { value="http://${aws_instance.taskops.public_ip}" }

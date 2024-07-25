output "instance_public_ips" {
  value = aws_instance.mongodb.*.public_ip
}

output "instance_private_ips" {
  value = aws_instance.mongodb.*.private_ip
}

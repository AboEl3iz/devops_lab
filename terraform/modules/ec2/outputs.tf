output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "EC2 public IP — use as EC2_PUBLIC_IP GitHub secret"
  value       = aws_instance.main.public_ip
}

output "public_dns" {
  description = "EC2 public DNS hostname"
  value       = aws_instance.main.public_dns
}

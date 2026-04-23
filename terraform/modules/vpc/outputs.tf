output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (for EC2)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (for RDS)"
  value       = aws_subnet.private[*].id
}

output "sg_ec2_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

output "sg_rds_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}

output "endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "host" {
  description = "RDS hostname only (without port) — for DB_HOST env var"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

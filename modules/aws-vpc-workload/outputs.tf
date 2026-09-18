output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "List of private data subnet IDs"
  value       = aws_subnet.private_data[*].id
}

output "transit_subnet_ids" {
  description = "List of transit subnet IDs"
  value       = aws_subnet.transit[*].id
}

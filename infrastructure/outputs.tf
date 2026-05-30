output "users_table_arn" {
  description = "ARN of the Users DynamoDB table"
  value       = aws_dynamodb_table.users_table.arn
}

output "users_table_id" {
  description = "ID of the Users DynamoDB table"
  value       = aws_dynamodb_table.users_table.id
}

output "users_table_name" {
  description = "Name of the Users DynamoDB table"
  value       = aws_dynamodb_table.users_table.name
}

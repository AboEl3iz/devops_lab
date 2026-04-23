output "function_name" {
  description = "Lambda function name — use as LAMBDA_FUNCTION_NAME GitHub secret"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.main.arn
}

output "api_gateway_url" {
  description = "API Gateway invoke URL — endpoint for the Lambda health check"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

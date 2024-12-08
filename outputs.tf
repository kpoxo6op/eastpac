output "mwaa_bucket_name" {
  description = "Name of the S3 bucket used for MWAA DAGs"
  value       = aws_s3_bucket.mwaa_bucket.id
}

output "mwaa_webserver_url" {
  description = "The webserver URL of the MWAA environment"
  value       = aws_mwaa_environment.mwaa_environment.webserver_url
} 
############################################
# Terraform Backend Outputs
############################################

output "tf_state_bucket_name" {
  description = "S3 bucket name used for Terraform remote state."
  value       = aws_s3_bucket.tf_state.bucket
}

output "tf_state_bucket_arn" {
  description = "ARN of the Terraform remote state bucket."
  value       = aws_s3_bucket.tf_state.arn
}

output "dynamodb_lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.tf_locks.name
}

############################################
# Platform Root KMS Outputs
############################################

output "platform_kms_key_arn" {
  description = "ARN of the platform root KMS key."
  value       = aws_kms_key.platform_root.arn
}

output "platform_kms_alias" {
  description = "Alias of the platform root KMS key."
  value       = aws_kms_alias.platform_root.name
}

############################################
# IPAM Outputs
############################################

output "ipam_id" {
  description = "ID of the AWS IPAM instance."
  value       = aws_vpc_ipam.platform.id
}

output "ipam_private_scope_id" {
  description = "Private IPAM scope ID (used by governed IPAM pool modules)."
  value       = local.private_scope_id
}

output "ipam_public_scope_id" {
  description = "Public IPAM scope ID (used by internet-facing pools)."
  value       = local.public_scope_id
}

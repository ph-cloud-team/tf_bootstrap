############################################
# AWS Region
############################################
# Region in which all Tier-0 bootstrap
# resources will be created.
variable "region" {
  description = "AWS region for bootstrap resources."
  type        = string
}

############################################
# Platform Naming Prefix
############################################
# Enterprise-wide prefix used to name
# foundational platform resources.
# Example: midhtech, org-platform, corp-cloud
variable "name_prefix" {
  description = "Enterprise platform naming prefix."
  type        = string
}

############################################
# Terraform State Bucket Name
############################################
# Deterministic S3 bucket name used as the
# Terraform remote backend for all environments.
variable "tf_state_bucket_name" {
  description = "Deterministic S3 bucket name for Terraform remote state."
  type        = string
}

############################################
# DynamoDB Lock Table Name
############################################
# DynamoDB table used for Terraform state
# locking and concurrency control.
variable "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
}

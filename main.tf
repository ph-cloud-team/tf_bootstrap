############################################
# Provider Configuration
############################################
# Allowed in this repository because this is
# a Tier-0 bootstrap control-plane repo.
provider "aws" {
  region = var.region
}

############################################
# KMS — Platform Root CMK (Bootstrap)
############################################
# This is the root encryption key for the
# entire platform. It is used for:
# - Terraform remote state encryption
# - Future EKS secrets encryption
# - Future logging encryption
#
# This key is long-lived, global in scope,
# and created only once.
resource "aws_kms_key" "platform_root" {
  description             = "Platform root KMS key (bootstrap)"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name          = "${var.name_prefix}-platform-root"
    managed_by    = "terraform"
    lifecycle     = "bootstrap"
    resource_role = "kms-root"
  }
}

# Human-readable alias for the platform CMK
resource "aws_kms_alias" "platform_root" {
  name          = "alias/${var.name_prefix}-platform-root"
  target_key_id = aws_kms_key.platform_root.key_id
}

############################################
# S3 — Terraform Remote State Bucket
############################################
# Deterministic bucket used as the Terraform
# remote backend for all environments.
resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket_name
}

############################################
# S3 Bucket Versioning
############################################
# Required for state recovery, auditability,
# and rollback.
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

############################################
# S3 Server-Side Encryption (SSE-KMS)
############################################
# Enforces encryption at rest using the
# platform root CMK.
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.platform_root.arn
    }
  }
}

############################################
# S3 Public Access Block
############################################
# Terraform state must never be public.
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# S3 Bucket Policy — Security Enforcement
############################################
# Enforces TLS, SSE-KMS, and correct KMS key
# usage at the policy layer.
resource "aws_s3_bucket_policy" "tf_state_policy" {
  bucket = aws_s3_bucket.tf_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Deny non-TLS access
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tf_state.arn,
          "${aws_s3_bucket.tf_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },

      # Deny uploads without SSE-KMS
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.tf_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },

      # Deny uploads using the wrong KMS key
      {
        Sid       = "DenyWrongKmsKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.tf_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.platform_root.arn
          }
        }
      }
    ]
  })
}

############################################
# S3 Bucket Ownership Controls
############################################
# Enforces bucket owner control over objects.
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

############################################
# DynamoDB — Terraform State Locking
############################################
# Prevents concurrent Terraform operations
# and enables safe CI/CD execution.
resource "aws_dynamodb_table" "tf_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enables recovery from accidental deletes
  point_in_time_recovery {
    enabled = true
  }
}

############################################
# IPAM — Instance (Bootstrap)
############################################
# Creates the global IPAM service used for
# centralized CIDR governance.
#
# No pools are created here. Pools are
# created later via governed modules.
resource "aws_vpc_ipam" "platform" {
  description = "Platform IPAM (bootstrap)"

  operating_regions {
    region_name = var.region
  }

  tags = {
    Name          = "${var.name_prefix}-ipam"
    managed_by    = "terraform"
    lifecycle     = "bootstrap"
    resource_role = "ipam"
  }
}

############################################
# IPAM — Default Scopes (Provider v5)
############################################
# AWS automatically creates one public and
# one private scope for every IPAM.
# These are now exposed directly by the
# aws_vpc_ipam resource in v5+.
locals {
  private_scope_id = aws_vpc_ipam.platform.private_default_scope_id
  public_scope_id  = aws_vpc_ipam.platform.public_default_scope_id
}

############################################
# Terraform & Provider Versions
############################################
# Versions are pinned to prevent drift
# in the platform control plane.
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

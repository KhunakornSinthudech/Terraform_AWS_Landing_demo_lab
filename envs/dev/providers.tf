terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws     = { source = "hashicorp/aws", version = ">= 5.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.4" } // for lambda zip
  }
  # backend "local" { path = "terraform.tfstate" }
}

provider "aws" {
  region = var.region
  default_tags { tags = var.tags }
}

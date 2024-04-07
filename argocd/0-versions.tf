terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.62"
    }
    argocd = {
      source = "oboukili/argocd"
      version = "6.1.1"
    }
  }
}
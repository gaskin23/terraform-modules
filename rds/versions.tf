terraform {
  required_version = ">= 1.0"

  required_providers {
    random = {
      source = "hashicorp/random"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}
## ArgoCD server
variable "argocd_chart_version" {
  type    = string
  default = "6.7.7"
}

variable "argocd_chart_name" {
  type    = string
  default = "argocd"
}

variable "argocd_k8s_namespace" {
  type    = string
  default = "argocd"
}

variable "env" {
  description = "Environment name."
  type        = string
}

variable "eks_name" {
  description = "Name of the cluster."
  type        = string
}

variable "openid_provider_arn" {
  description = "IAM Openid Connect Provider ARN"
  type        = string
}

variable "private_key_path" {
  description = "Path to the SSH private key"
  default     = "~/.ssh/id_rsa"
}
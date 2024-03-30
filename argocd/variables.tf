## ArgoCD server
variable "argocd_chart_version" {
  type    = string
  default = "5.53.8"
}

variable "argocd_chart_name" {
  type    = string
  default = "argo-cd"
}

variable "argocd_k8s_namespace" {
  type    = string
  default = "argo-cd"
}
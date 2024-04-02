data "aws_iam_openid_connect_provider" "argo" {
  arn = var.openid_provider_arn
}



module "iam_assumable_role_oidc" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.2.0"

  create_role = true
  role_name   = "k8s-argocd-admin"
  #provider_url = replace(data.terraform_remote_state.kubeconfig_file.outputs.cluster_oidc_issuer_url, "https://", "")
  provider_url                  = data.aws_iam_openid_connect_provider.argo.arn
  role_policy_arns              = []
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.argocd_k8s_namespace}:argocd-server", "system:serviceaccount:${var.argocd_k8s_namespace}:argocd-application-controller"]
  depends_on = [
    kubernetes_namespace.namespace_argocd
  ]
}

resource "kubernetes_namespace" "namespace_argocd" {
  metadata {
    name = var.argocd_k8s_namespace
  }
}

# resource "kubernetes_manifest" "voltran_app_project" {
#   #manifest = yamldecode(file("${path.module}/manifests/voltran-app-project.yaml"))
#   manifest = [file("${path.module}/manifests/voltran-app-project.yaml")]
#   depends_on = [
#     helm_release.argocd
#   ]
# }
resource "kubernetes_manifest" "voltran_project" {
  depends_on = [
     helm_release.argocd
  ]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "voltran"
      namespace = "argocd"
    }
    spec = {
      description = "Voltran Project"
      sourceRepos = [
        "*"
      ]
      destinations = [
        {
          namespace = "argocd"
          server    = "https://kubernetes.default.svc"
        },
        {
          namespace = "*"
          server    = "*"
        }
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  }
}



resource "kubernetes_manifest" "app_of_apps" {

  manifest = yamldecode(file("${path.module}/manifests/app-of-apps.yaml"))
  

  depends_on = [
    kubernetes_manifest.voltran_app_project
  ]
}


resource "helm_release" "argocd" {

  name       = var.argocd_chart_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = var.argocd_chart_name
  version    = var.argocd_chart_version
  namespace  = var.argocd_k8s_namespace
  values     = [file("${path.module}/manifests/values.yaml")]

  ## Server params

  set { # Annotations applied to created service account
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_oidc.iam_role_arn
  }

  set { # Define the application controller --app-resync - refresh interval for apps, default is 180 seconds
    name  = "controller.args.appResyncPeriod"
    value = "30"
  }

  set { # Define the application controller --repo-server-timeout-seconds - repo refresh timeout, default is 60 seconds
    name  = "controller.args.repoServerTimeoutSeconds"
    value = "15"
  }

  depends_on = [
    kubernetes_namespace.namespace_argocd,
    module.iam_assumable_role_oidc
  ]

}


apiVersion: v1
kind: Secret
metadata:
  name: argocd-private-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: git@github.com:gaskin23/guardian-task.git
  sshPrivateKey: |
    ${ssh_private_key}
  insecure: "false"
  enableLfs: "true"
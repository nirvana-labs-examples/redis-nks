module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 0.2.0"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  project_id         = var.project_id
  region             = var.region

  node_pools = {
    default = {
      node_count    = var.node_count
      instance_type = var.instance_type
    }
  }

  fetch_kubeconfig = var.fetch_kubeconfig
}

locals {
  redis_chart_path = "${path.module}/../redis"
}

# Pre-create the namespace so cluster RBAC grants access to it before
# helm_release runs its preflight. Helm reads existing release secrets
# from the target namespace first, which fails when secret access is
# namespace-scoped.
resource "kubernetes_namespace" "redis" {
  metadata {
    name = "redis"
  }
}

# Generated admin password. Terraform owns it via state; the chart picks
# it up by reference (auth.existingSecret), so the chart never templates
# the password into a manifest.
resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "redis_auth" {
  metadata {
    name      = "redis-auth"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }
  data = {
    password = random_password.redis_auth.result
  }
}

resource "helm_release" "redis" {
  name      = "redis"
  namespace = kubernetes_namespace.redis.metadata[0].name
  chart     = local.redis_chart_path

  values = [file("${local.redis_chart_path}/values.yaml")]

  set {
    name  = "auth.existingSecret"
    value = kubernetes_secret.redis_auth.metadata[0].name
  }

  set {
    name  = "auth.existingSecretPasswordKey"
    value = "password"
  }

  set {
    name  = "persistence.size"
    value = var.storage_size
  }

  set {
    name  = "service.type"
    value = var.service_type
  }

  # After the initial install, the values.yaml in your fork is the source
  # of truth — edits propagate via your GitOps tooling or `helm upgrade`.
  # Ignoring values/set here prevents Terraform from fighting subsequent
  # changes. The release itself still exists in state so `terraform destroy`
  # cleans up.
  lifecycle {
    ignore_changes = [values, set, version]
  }
}

# Read back the allocated LoadBalancer IP so it can be surfaced as a
# Terraform output. On the first apply this may be empty for a few seconds
# while the controller assigns an address — re-run terraform refresh or
# terraform apply if the output is null.
data "kubernetes_service" "redis" {
  depends_on = [helm_release.redis]
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }
}

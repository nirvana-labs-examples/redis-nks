variable "project_id" {
  description = "Nirvana Labs project ID."
  type        = string
}

variable "region" {
  description = "Nirvana Labs region."
  type        = string
  default     = "us-sva-2"
}

variable "cluster_name" {
  description = "NKS cluster name."
  type        = string
  default     = "redis-nks-demo"
}

variable "node_count" {
  description = "Worker node count (single pool)."
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "Worker instance type."
  type        = string
  default     = "n1-standard-4"
}

variable "fetch_kubeconfig" {
  description = "Whether to fetch the cluster kubeconfig and install Redis. Set to true on the second apply, after the control plane is reachable (~10 min after first apply)."
  type        = bool
  default     = false
}

variable "storage_size" {
  description = "Redis data PVC size."
  type        = string
  default     = "10Gi"
}

variable "service_type" {
  description = "Kubernetes Service type for Redis. LoadBalancer exposes it on the VPC subnet; ClusterIP keeps it in-cluster only."
  type        = string
  default     = "LoadBalancer"
}

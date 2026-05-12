output "kubeconfig_path" {
  description = "Path to the kubeconfig written for the cluster. Null until fetch_kubeconfig is true."
  value       = module.nks.kubeconfig_path
}

output "redis_lb_ip" {
  description = "LoadBalancer IP for Redis on the VPC subnet. Null until the controller assigns an IP after the second apply."
  value       = try(data.kubernetes_service.redis.status[0].load_balancer[0].ingress[0].ip, null)
}

output "redis_password_cmd" {
  description = "Shell command that prints the generated Redis password."
  value       = "kubectl get secret redis-auth -n redis -o jsonpath='{.data.password}' | base64 -d"
}

output "redis_test_cmd" {
  description = "Shell command that spins up an ephemeral redis-cli pod and PINGs Redis. eval \"$(terraform output -raw redis_test_cmd)\" to run."
  value       = <<-EOT
    kubectl run -it --rm redis-cli --image=redis:7.4-alpine --restart=Never -- redis-cli -h redis.redis.svc.cluster.local -a "$(kubectl get secret redis-auth -n redis -o jsonpath='{.data.password}' | base64 -d)" PING
  EOT
}

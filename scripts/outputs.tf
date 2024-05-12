output "kubernetes_master_ip" {
  value = aws_instance.kubernetes_master.public_ip
}

output "kubernetes_worker_1_ip" {
  value = aws_instance.kubernetes_worker_1.public_ip
}

output "kubernetes_worker_2_ip" {
  value = aws_instance.kubernetes_worker_2.public_ip
}

output "monitoring_server_ip" {
  value = aws_instance.monitoring_server.public_ip
}

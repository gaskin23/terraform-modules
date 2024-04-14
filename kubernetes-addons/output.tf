output "load_balancer_security_group_id" {
  value       = aws_security_group.lb_sg.id
  description = "The ID of the security group for the Load Balancer"
}
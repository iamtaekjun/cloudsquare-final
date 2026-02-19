output "alb_id"         { value = ncloud_lb.main.load_balancer_no }
output "alb_domain"     { value = ncloud_lb.main.domain }
output "target_group_no" { value = ncloud_lb_target_group.webwas.target_group_no }

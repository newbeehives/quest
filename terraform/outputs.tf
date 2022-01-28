output "rearc_quest_box_ip" {
  description = "Public IP of the rearc quest box EC2 instance."
  value       = module.ec2_instance.public_ip[0]
}

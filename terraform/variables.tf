variable "aws_region" {
  description = "AWS region code where this infra is deployed."
  default = "us-east-1"
}

variable "infra_prefix" {
  description = "The prefix to prepeand to named resources in this infra."
  default = "binu-rearc-quest"
}

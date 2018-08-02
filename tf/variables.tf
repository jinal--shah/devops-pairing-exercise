# vim: et sr sw=2 ts=2 smartindent:
variable "vpc_id" {
  description = "affected stack's vpc"
  default     = "vpc-8bc8d2ef"
}

variable "subnet_ids_public" {
  type        = "list"
  description = "subnets which elb will utilise to talk to web-tier"
  default     = ["subnet-48de3e2f","subnet-313cdf78"]
}

variable "product" {
  description = "... used in aws tags, names and path to remote_state"
  default     = "101ways-nginx"
}

variable "stack_name" {
  description = "... used in aws tags, names and path to remote_state"
  default     = "int"
}

variable "object_name" {
  description = "prefix for this terraform's provisioned objects"
  default     = "int-101ways-nginx"
}

variable "deploy_id" {
  description = "unique id for this terraform run"
}

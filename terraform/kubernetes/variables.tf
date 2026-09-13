variable "folder_id" {
  type = string
}
variable "zone" {
  type    = string
  default = "ru-central1-a"
}
variable "trusted_cidrs" {
  description = "Administrator public IPv4 CIDRs, normally a single /32."
  type        = list(string)
  validation {
    condition     = length(var.trusted_cidrs) > 0 && alltrue([for c in var.trusted_cidrs : can(cidrnetmask(c)) && !endswith(c, "/0")])
    error_message = "Supply trusted IPv4 CIDRs; /0 is forbidden."
  }
}
variable "postgres_password" {
  type      = string
  sensitive = true
}
variable "postgres_preset" {
  type    = string
  default = "s3-c2-m8"
}
variable "kubernetes_version" {
  description = "Select a currently supported version using yc managed-kubernetes list-versions."
  type        = string
}
variable "node_cores" {
  type    = number
  default = 4
}
variable "node_memory" {
  type    = number
  default = 8
}
variable "enable_nlb" {
  description = "Allow external TCP 80 to the dedicated NLB NodePort for lab 8 only."
  type        = bool
  default     = false
}

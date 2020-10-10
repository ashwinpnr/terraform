variable "default_tags" {
  description = "Default Tags for all terraform managed resources."
  type        = map(string)
  default     = { "managed-by" = "terraform" }
}
variable "default_tags" {}
variable "environment_tags" {
  description = "Default Tags for all terraform managed resources."
  type        = map(string)
  default     = {"Environment"= "testing"}
}
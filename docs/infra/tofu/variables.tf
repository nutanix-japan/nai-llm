variable "cluster_name" {
  type = string
}
variable "subnet_name" {
  type = string
}
variable "password" {
  description = "nutanix cluster password"
  type      = string
  sensitive = true

}
variable "endpoint" {
  type = string
}
variable "user" {
  description = "nutanix cluster username"
  type      = string
  sensitive = true
}


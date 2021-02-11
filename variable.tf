variable "user" {
  description = "Login information"
  type        = map
  default     = {
    username = "admin"
    password = "Cisco123%"
    url      = "https://apic-ip"
  }
}
variable "tenant" {
    type    = string
    default = "Tenant-JC"
}
variable "tenant-user" {
  description = "Tenant User Account Information"
  type        = map
  default     = {
    accesskey = "youraccesskey"
    secretkey = "yoursecretkey"
    accountid = "yourtenant-user-account-id"
  }
}
variable "vrf" {
    type    = string
    default = "vrf1"
}
variable "anp" {
    type    = string
    default = "ANP1"
}
variable "cidr" {
  description = "VPC/vrf subnets"
  type        = map
  default     = {
    addr = "192.168.0.0/16"
    subnet1 = "192.168.100.0/24"
    subnet2 = "192.168.200.0/24"
  }
}
variable "contract" {
  description = "contracts"
  type        = map
  default     = {
    contract1 = "contract-app-web"
    contract2 = "contract-internet"
  }
}
variable "epg" {
  description = "epgs"
  type        = map
  default     = {
    epg1 = "epg-web"
    epg2 = "epg-app"
    epg-external = "epg-internet"
  }
}
variable "selector-epg" {
  description = "epgs"
  type        = map
  default     = {
    selector1 = "selector-web"
    selector2 = "selector-app"
  }
}

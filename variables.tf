variable "resource_group_name_primary" {
   description = "Name of the resource group in which the resources will be created"
   default     = "rg-wapp-eastus2"
}

variable "location-primary" {
   default = "eastus2"
   description = "Location where resources will be created"
}

variable "resource_group_name_secondary" {
   description = "Name of the resource group in which the resources will be created"
   default     = "rg-wapp-centralus"
}

variable "location-secondary" {
   default = "centralus"
   description = "Location where resources will be created"
}

variable "tags" {
   description = "Map of the tags to use for the resources that are deployed"
   type        = map(string)
   default = {
      environment = "wapp"
   }
}

variable "application_port" {
   description = "Port that you want to expose to the external load balancer"
   default     = 80
}

variable "admin_user" {
   description = "User name to use as the admin account on the VMs that will be part of the VM scale set"
   default = "samshaik"
}

variable "admin_password" {
   description = "Default password for admin account"
  default = "CyN20137@ave"
}

variable "sql-login" {
  type = string
   default = "samshaik"
}

variable "sql-password" {
  type = string
  default = "CyN20137@ave"
}

variable "sql-threat-email" {
  type = string
  default = "shaiksameer@shaiksameer.com"
}

variable "startip" {
  default = "64.225.23.42"
}

variable "endip" {
  default = "64.225.23.42"
}

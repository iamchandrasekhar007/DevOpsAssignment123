variable "rg_name" {
    default = "rg1"
  
}
variable "rg_location" {

  default = "east us"
}

variable "vnet_name" {
    default = "vnet01"
  
}
variable "vnet_ip_address" {
    default = ["10.1.0.0/16"]
  
}

variable "public_subnet_prefixes" {
    type    = list(string)
    default = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  
}

variable "private_subnet_prefixes" {
    type    = list(string)
   default = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
}

variable "firewall_subnet" {
    default = ["10.1.7.0/24"]
  
}

variable "tags" {
  default = {
    Environment = "dev"
    Project     = "azure-vpc-assignment"
    Owner       = "sivaDevOps"
  }
}


variable "region" {
    default = "us-east-2"
}

variable "shared_credentials_file" {
  default = "/Users/dashy10/.aws/credentials"
}

variable "profile" {
  default = "terraform"
}

variable "ServiceName" {
  type = "string"
  default = "dashielllumas-quest"
}

variable "ContainerCpu" {
  type = "string"
  default = "256"
}

variable "ContainerMemory" {
  type = "string"
  default = "512"
}
variable "ImageUrl" {
  type = "string"
  default = ""
}
variable "Route53ZoneName" {
  type = "string"
  default = "dashielllumas-origin" 
}
variable "Route53HostedZoneID" {
  type = "string"
  default = "Z1BEOO2A5FWP1D"
}
variable "Route53Prefix" {
  type = "string"
  default = "dashielllumas"
}

variable "Route53HostedZoneDomainName" {
  type = "string"
  default = "quest.rearc.io."
}

variable "load_balancer_type" {
  type = "string"
  default = "application"
}
variable "ip_address_type" {
  type = "string"
  default = "ipv4"
}
variable "private_key_path" {
  type = string
  default = "~/.ssh/rsa_private_key"
}

variable "public_key_path" {
  type = string
  default = "~/.ssh/rsa_public_key"
  sensitive = true
}

variable "zones" {
  type = map
  default = {
    "amsterdam" = "nl-ams1"
    "london"    = "uk-lon1"
    "frankfurt" = "de-fra1"
    "helsinki1" = "fi-hel1"
    "helsinki2" = "fi-hel2"
    "chicago"   = "us-chi1"
    "sanjose"   = "us-sjo1"
    "singapore" = "sg-sin1"
    "sydney"    = "au-syd1"
    "warsaw"    = "pl-waw1"
    "madrid"    = "es-mad1"
    "newyork"   = "us-nyc1"
  }
}

variable "plans" {
  type = map
  default = {
    "5USD"    = "1xCPU-1GB"
    "10USD"   = "1xCPU-2GB"
    "20USD"   = "2xCPU-4GB"
    "40USD"   = "4xCPU-8GB"
    "80USD"   = "6xCPU-16GB"
    "160USD"  = "8xCPU-32GB"
    "240USD"  = "12xCPU-48GB"
    "320USD"  = "16xCPU-64GB"
    "490USD"  = "20xCPU-96GB"
    "640USD"  = "20xCPU-128GB"
  }
}

variable "storage_sizes" {
  type = map
  default = {
    "1xCPU-1GB"    = "25"
    "1xCPU-2GB"    = "50"
    "2xCPU-4GB"    = "80"
    "4xCPU-8GB"    = "160"
    "6xCPU-16GB"   = "320"
    "8xCPU-32GB"   = "640"
    "12xCPU-48GB"  = "960"
    "16xCPU-64GB"  = "1280"
    "20xCPU-96GB"  = "1920"
    "20xCPU-128GB" = "2048"
  }
}
variable "templates" {
  type = map
  default = {
    "centos7"     = "01000000-0000-4000-8000-000050010300"
    "almalinux8"  = "01000000-0000-4000-8000-000140010100"
    "rockylinux8" = "01000000-0000-4000-8000-000150010100"
  }
}

variable "set_password" {
  type = bool
  default = false
}

variable "users" {
  type = list
  default = ["root", "user1", "user2"]
}

variable "plan" {
  type = string
  default = "40USD"
}

variable "template" {
  type = string
  default = "centos7"
}
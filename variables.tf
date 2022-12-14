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
    "5USD"     = "1xCPU-1GB"
    "10USD"    = "1xCPU-2GB"
    "20USD"    = "2xCPU-4GB"
    "40USD"    = "4xCPU-8GB"
    "80USD"    = "6xCPU-16GB"
    "160USD"   = "8xCPU-32GB"
    "240USD"   = "12xCPU-48GB"
    "320USD"   = "16xCPU-64GB"
    "490USD"   = "20xCPU-96GB"
    "640USD"   = "20xCPU-128GB"
    "40USDM"   = "HIMEM-2xCPU-8GB"
    "65USDM"   = "HIMEM-2xCPU-16GB"
    "132USDM"  = "HIMEM-4xCPU-32GB"
    "240USDM"  = "HIMEM-4xCPU-64GB"
    "480USDM"  = "HIMEM-6xCPU-128GB"
    "840USDM"  = "HIMEM-8xCPU-192GB"
    "1080USDM" = "HIMEM-12xCPU-256GB"
    "1680USDM" = "HIMEM-16xCPU-384GB"
    "130USDC"  = "HICPU-8xCPU-12GB"
    "160USDC"  = "HICPU-8xCPU-16GB"
    "260USDC"  = "HICPU-16xCPU-24GB"
    "310USDC"  = "HICPU-16xCPU-32GB"
    "530USDC"  = "HICPU-32xCPU-48GB"
    "620USDC"  = "HICPU-32xCPU-64GB"
    "1056USDC" = "HICPU-64xCPU-96GB"
    "1248USDC" = "HICPU-64xCPU-128GB"

  }
}

variable "storage_sizes" {
  type = map
  default = {
    "1xCPU-1GB"          = "25"
    "1xCPU-2GB"          = "50"
    "2xCPU-4GB"          = "80"
    "4xCPU-8GB"          = "160"
    "6xCPU-16GB"         = "320"
    "8xCPU-32GB"         = "640"
    "12xCPU-48GB"        = "960"
    "16xCPU-64GB"        = "1280"
    "20xCPU-96GB"        = "1920"
    "20xCPU-128GB"       = "2048"
    "HIMEM-2xCPU-8GB"    = "100"
    "HIMEM-2xCPU-16GB"   = "100"
    "HIMEM-4xCPU-32GB"   = "100"
    "HIMEM-4xCPU-64GB"   = "200"
    "HIMEM-6xCPU-128GB"  = "300"
    "HIMEM-8xCPU-192GB"  = "400"
    "HIMEM-12xCPU-256GB" = "500"
    "HIMEM-16xCPU-384GB" = "600"
    "HICPU-8xCPU-12GB"   = "100"
    "HICPU-8xCPU-16GB"   = "200"
    "HICPU-16xCPU-24GB"  = "100"
    "HICPU-16xCPU-32GB"  = "200"
    "HICPU-32xCPU-48GB"  = "200"
    "HICPU-32xCPU-64GB"  = "300"
    "HICPU-64xCPU-96GB"  = "200"
    "HICPU-64xCPU-128GB" = "300"
  }
}

variable "templates" {
  type = map
  default = {
    "centos7"     = "01000000-0000-4000-8000-000050010300"
    "almalinux8"  = "01000000-0000-4000-8000-000140010100"
    "rockylinux8" = "01000000-0000-4000-8000-000150010100"
    "almalinux9"  = "01000000-0000-4000-8000-000140020100"
    "rockylinux9" = "01000000-0000-4000-8000-000150020100"
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
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
    "132USBM"  = "HIMEM-4xCPU-32GB"
    "240USBM"  = "HIMEM-4xCPU-64GB"
    "480USBM"  = "HIMEM-6xCPU-128GB"
    "840USBM"  = "HIMEM-8xCPU-192GB"
    "1080USBM" = "HIMEM-12xCPU-256GB"
    "1680USBM" = "HIMEM-16xCPU-384GB"
    "130USBC"  = "HICPU-8xCPU-12GB"
    "160USBC"  = "HICPU-8xCPU-16GB"
    "260USBC"  = "HICPU-16xCPU-24GB"
    "310USBC"  = "HICPU-16xCPU-32GB"
    "530USBC"  = "HICPU-32xCPU-48GB"
    "620USBC"  = "HICPU-32xCPU-64GB"
    "1056USBC" = "HICPU-64xCPU-96GB"
    "1248USBC" = "HICPU-64xCPU-128GB"

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
    "40USDM"   = "100"
    "65USDM"   = "100"
    "132USBM"  = "100"
    "240USBM"  = "200"
    "480USBM"  = "300"
    "840USBM"  = "400"
    "1080USBM" = "500"
    "1680USBM" = "600"
    "130USBC"  = "100"
    "160USBC"  = "200"
    "260USBC"  = "100"
    "310USBC"  = "200"
    "530USBC"  = "200"
    "620USBC"  = "300"
    "1056USBC" = "200"
    "1248USBC" = "300"
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
# Upcloud Terraform Based Server Installation

Terraform based server install at Upcloud using guide outlined at https://upcloud.com/resources/tutorials/get-started-terraform & https://www.terraform.io/downloads. If you like this guide and want to try out Upcloud, use my referral link [here](https://centminmod.com/upcloud/).

* [Install Terraform](#install-terraform)
* [Setup Upcloud API Credentials](#setup-upcloud-api-credentials)
* [Initialize New Terraform Project](#initialize-new-terraform-project)
* [Planning Infrastructure With Terraform](#planning-infrastructure-with-terraform)
  * [Variable Template Method](#variable-template-method)
  * [Specific Terraform definition files](#specific-terraform-definition-files)
  * [Defining Output Variables](#defining-output-variables)
  * [Viewing User Data Progress](#viewing-user-data-progress)
* [Using upctl Command Line Tool](#using-upctl-command-line-tool)
* [Deleting Terraform Created Server](#deleting-terraform-created-server)
* [Upcloud Region List](#upcloud-region-list)
* [Upcloud Plan List](#upcloud-plan-list)
* [OS Template Storage UUID](#os-template-storage-uuid)

# Install Terraform & upctl

* https://upcloud.com/resources/tutorials/get-started-upcloud-command-line-interface

```
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform
```
```
terraform -v
Terraform v1.2.9
on linux_amd64
```

Download upctl command line tool from https://github.com/UpCloudLtd/upcloud-cli/releases

```
upctl_version=2.1.0
curl -L -o upcloud-cli.tar.gz https://github.com/UpCloudLtd/upcloud-cli/releases/download/v${upctl_version}/upcloud-cli_${upctl_version}_linux_x86_64.tar.gz
tar -C /usr/local/bin -xf upcloud-cli.tar.gz
wget https://github.com/centminmod/upcloud-terraform/raw/master/upctl/bash_completion.d/upctl -O /etc/bash_completion.d/upctl
source /etc/bash_completion.d/upctl
```

# Setup Upcloud API Credentials

Create a new API Access key as outlined at https://upcloud.com/community/tutorials/%20/getting-started-upcloud-api/ and replace the `UPCLOUD_USERNAME` and `UPCLOUD_PASSWORD` variable values `username` and `password` with your Upcloud API credentials and run the below commands to populate `~/.bashrc`. Then apply the new additions.

```
echo 'export UPCLOUD_USERNAME=username' | tee -a ~/.bashrc
echo 'export UPCLOUD_PASSWORD=password' | tee -a ~/.bashrc
source ~/.bashrc
```

This will work for both Terraform and upctl command line tool.

# Initialize New Terraform Project

Create a new directory for your Terraform project and change into it.

```
mkdir -p /home/terraform/base
cd /home/terraform/base
```

Deploying Cloud Servers on UpCloud using Terraform works using the [verified provider module](https://registry.terraform.io/providers/UpCloudLtd/upcloud/latest).

Create `/home/terraform/base/version.tf`

```
touch version.tf
```

Place in `/home/terraform/base/version.tf`

```
terraform {
  required_providers {
    upcloud = {
      source = "UpCloudLtd/upcloud"
    }
  }
}

provider "upcloud" {
  # Your UpCloud credentials are read from the environment variables
  # export UPCLOUD_USERNAME="Username for Upcloud API user"
  # export UPCLOUD_PASSWORD="Password for Upcloud API user"
  # Optional configuration settings can be depclared here
}
```

```
terraform init
```

The initialisation process creates a directory for the plugins in your Terraform folder under `.terraform/providers` and installs the UpCloud provider module. The Terraform installation for UpCloud is then all set.

```
ls -lah .terraform/providers/registry.terraform.io/upcloudltd/upcloud/2.5.0/linux_amd64/
total 17M
drwxr-xr-x 2 root root 4.0K Sep 14 09:07 .
drwxr-xr-x 3 root root 4.0K Sep 14 09:07 ..
-rw-rw-rw- 1 root root 9.0K Sep 14 09:07 CHANGELOG.md
-rw-rw-rw- 1 root root 1.1K Sep 14 09:07 LICENSE
-rw-rw-rw- 1 root root  607 Sep 14 09:07 README.md
-rwxr-xr-x 1 root root  17M Sep 14 09:07 terraform-provider-upcloud_v2.5.0
```

# Planning Infrastructure With Terraform


Using values from https://developers.upcloud.com/1.3/ and https://upcloud.com/resources/tutorials/reduce-downtime-terraform-redeployments. Later you can create variables outlined at https://upcloud.com/resources/tutorials/terraform-variables.

Create `server1.tf`

```
touch server1.tf
```

Using:

* zone = `us-nyc1` [list of regions](#region-list)
* plan = `4xCPU-8GB` [list of plans](#plan-list)
* storage template [list of OS storage templete UUIDs](#os-template-storage-uuid)
  * for CentOS 7 UUID = `01000000-0000-4000-8000-000050010300` with size = `160GB`
  * for AlmaLinux 8 UUID = `01000000-0000-4000-8000-000140010100` with size = `160GB`
  * for Rocky Linux 8 UUID = `01000000-0000-4000-8000-000150010100` with size = `160GB`
  * for AlmaLinux 9 UUID = `01000000-0000-4000-8000-000140020100` with size = `160GB`
  * for Rocky Linux 9 UUID = `01000000-0000-4000-8000-000150020100` with size = `160GB`

* save your desired SSH public key into `~/.ssh/rsa_public_key` and corresponding SSH private key into `~/.ssh/rsa_private_key`
* The user data scripted section is configured the way it is as in that environment the `$HOME` variable for root user ends up as `/` while in a normal SSH terminal session `$HOME` is `/root`. This difference seems to break any scripting which relies of `$HOME` variables. The `RANDFILE` is for `openssl` binary operations to work properly if you use scripts which run `openssl` binary.
* Change the default `remote-exec` script path from running at `/tmp` in case server has noexec set on `/tmp`. So set in `connection` block `script_path = "/home/tftmp/terraform_%RAND%.sh"`(https://www.terraform.io/language/resources/provisioners/connection)

**Notes:** 

1. looks like for AlmaLinux 9 and Rocky Linux 9, they are using `cloud-init` templates and need to have Upcloud's Metadata enabled otherwise, you'd get an error like:

```
???
??? Error: Metadata must be enabled when cloning a cloud-init template (METADATA_DISABLED_ON_CLOUD-INIT)
??? 
???   with upcloud_server.server1,
???   on server1.tf line 1, in resource "upcloud_server" "server1":
???    1: resource "upcloud_server" "server1" {
??? 
???
```

2. EL9 OSes have SELinux enabled by default and you'd want to disable that before installing Centmin Mod. Centmin Mod can't automatically disable SELinux in EL9 like it can in EL7/EL8 OSes. 

```
grep '^SELINUX=' /etc/selinux/config
SELINUX=enforcing
```

Contents of `server1.tf`

```
resource "upcloud_server" "server1" {
  # System hostname
  hostname = "terraform.example.com"

  # Availability zone
  zone = "us-nyc1"

  # Number of CPUs and memory in GB
  plan = "4xCPU-8GB"

  metadata = true

  template {
    # System storage device size
    size = 160

    # Template UUID for CentOS 7
    storage = "01000000-0000-4000-8000-000050010300"
  }

  # Network interfaces
  network_interface {
    type = "public"
  }

  network_interface {
    type = "utility"
  }

  # Include at least one public SSH key
  login {
    user = "root"
    keys = [
      file("~/.ssh/rsa_public_key")
    ]
    create_password = false
    password_delivery = "email"
  }

  # Configuring connection details
  connection {
    # The server public IP address
    host        = self.network_interface[0].ip_address
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/rsa_private_key")
    script_path = "/home/terraform_%RAND%.sh"
  }

  # Remotely executing a command on the server
  provisioner "remote-exec" {
    inline = [
      "echo 'Hello world!'"
    ]
  }

  user_data = <<-EOF
  export TERM=xterm-256color
  mkdir -p /root
  export HOME=/root
  echo $HOME
  touch $HOME/.rnd
  export RANDFILE=$HOME/.rnd
  chmod 600 $HOME/.rnd
  env
  yum -y update
  EOF

 # Remotely executing a command on the server
  provisioner "remote-exec" {
    inline = [
        "echo",
        "lscpu",
        "echo",
        "free -mlt",
        "echo",
        "df -hT",
        "echo",
        "cat /etc/redhat-release"
    ]
  }
}
```

You can optionally enable backups by adding to `template{}` block

```
  backup_rule {
    interval  = "daily"
    time      = "0100"
    retention = 8
  }
```

```
terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # upcloud_server.server1 will be created
  + resource "upcloud_server" "server1" {
      + cpu       = (known after apply)
      + hostname  = "terraform.example.com"
      + id        = (known after apply)
      + mem       = (known after apply)
      + plan      = "4xCPU-8GB"
      + user_data = <<-EOT
              export TERM=xterm-256color
              mkdir -p /home/tftmp
              sleep 5
              chmod 1777 /home/tftmp
              mkdir -p /root
              export HOME=/root
              echo $HOME
              touch $HOME/.rnd
              export RANDFILE=$HOME/.rnd
              chmod 600 $HOME/.rnd
              env
              yum -y update

          
        EOT
      + zone      = "us-nyc1"

      + login {
          + create_password   = false
          + keys              = [
              + "ssh-rsa XYZABC",
            ]
          + password_delivery = "email"
          + user              = "root"
        }

      + network_interface {
          + bootable            = false
          + ip_address          = (known after apply)
          + ip_address_family   = "IPv4"
          + ip_address_floating = (known after apply)
          + mac_address         = (known after apply)
          + network             = (known after apply)
          + source_ip_filtering = true
          + type                = "public"
        }
      + network_interface {
          + bootable            = false
          + ip_address          = (known after apply)
          + ip_address_family   = "IPv4"
          + ip_address_floating = (known after apply)
          + mac_address         = (known after apply)
          + network             = (known after apply)
          + source_ip_filtering = true
          + type                = "utility"
        }

      + template {
          + address                  = (known after apply)
          + delete_autoresize_backup = false
          + filesystem_autoresize    = false
          + id                       = (known after apply)
          + size                     = 160
          + storage                  = "01000000-0000-4000-8000-000050010300"
          + tier                     = (known after apply)
          + title                    = (known after apply)
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

upcloud_server.server1: Creating...
upcloud_server.server1: Still creating... [10s elapsed]
upcloud_server.server1: Still creating... [20s elapsed]
upcloud_server.server1: Still creating... [30s elapsed]
upcloud_server.server1: Provisioning with 'remote-exec'...
upcloud_server.server1 (remote-exec): Connecting to remote host via SSH...
upcloud_server.server1 (remote-exec):   Host: 209.xxx.xxx.xxx
upcloud_server.server1 (remote-exec):   User: root
upcloud_server.server1 (remote-exec):   Password: false
upcloud_server.server1 (remote-exec):   Private key: true
upcloud_server.server1 (remote-exec):   Certificate: false
upcloud_server.server1 (remote-exec):   SSH Agent: true
upcloud_server.server1 (remote-exec):   Checking Host Key: false
upcloud_server.server1 (remote-exec):   Target Platform: unix
upcloud_server.server1: Still creating... [40s elapsed]
upcloud_server.server1: Still creating... [50s elapsed]
upcloud_server.server1 (remote-exec): Connecting to remote host via SSH...
upcloud_server.server1 (remote-exec):   Host: 209.xxx.xxx.xxx
upcloud_server.server1 (remote-exec):   User: root
upcloud_server.server1 (remote-exec):   Password: false
upcloud_server.server1 (remote-exec):   Private key: true
upcloud_server.server1 (remote-exec):   Certificate: false
upcloud_server.server1 (remote-exec):   SSH Agent: true
upcloud_server.server1 (remote-exec):   Checking Host Key: false
upcloud_server.server1 (remote-exec):   Target Platform: unix
upcloud_server.server1 (remote-exec): Connected!

upcloud_server.server1 (remote-exec): Architecture:          x86_64
upcloud_server.server1 (remote-exec): CPU op-mode(s):        32-bit, 64-bit
upcloud_server.server1 (remote-exec): Byte Order:            Little Endian
upcloud_server.server1 (remote-exec): CPU(s):                4
upcloud_server.server1 (remote-exec): On-line CPU(s) list:   0-3
upcloud_server.server1 (remote-exec): Thread(s) per core:    1
upcloud_server.server1 (remote-exec): Core(s) per socket:    1
upcloud_server.server1 (remote-exec): Socket(s):             4
upcloud_server.server1 (remote-exec): NUMA node(s):          1
upcloud_server.server1 (remote-exec): Vendor ID:             AuthenticAMD
upcloud_server.server1 (remote-exec): CPU family:            23
upcloud_server.server1 (remote-exec): Model:                 49
upcloud_server.server1 (remote-exec): Model name:            AMD EPYC 7542 32-Core Processor
upcloud_server.server1 (remote-exec): Stepping:              0
upcloud_server.server1 (remote-exec): CPU MHz:               2894.558
upcloud_server.server1 (remote-exec): BogoMIPS:              5789.11
upcloud_server.server1 (remote-exec): Hypervisor vendor:     KVM
upcloud_server.server1 (remote-exec): Virtualization type:   full
upcloud_server.server1 (remote-exec): L1d cache:             64K
upcloud_server.server1 (remote-exec): L1i cache:             64K
upcloud_server.server1 (remote-exec): L2 cache:              512K
upcloud_server.server1 (remote-exec): L3 cache:              16384K
upcloud_server.server1 (remote-exec): NUMA node0 CPU(s):     0-3
upcloud_server.server1 (remote-exec): Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm art rep_good nopl extd_apicid eagerfpu pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw perfctr_core retpoline_amd ssbd ibrs ibpb stibp vmmcall fsgsbase tsc_adjust bmi1 avx2 smep bmi2 rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 clzero xsaveerptr arat umip spec_ctrl intel_stibp arch_capabilities

upcloud_server.server1 (remote-exec):               total        used        free      shared  buff/cache   available
upcloud_server.server1 (remote-exec): Mem:           7802         339        7030          17         432        7215
upcloud_server.server1 (remote-exec): Low:           7802         772        7030
upcloud_server.server1 (remote-exec): High:             0           0           0
upcloud_server.server1 (remote-exec): Swap:             0           0           0
upcloud_server.server1 (remote-exec): Total:         7802         339        7030

upcloud_server.server1 (remote-exec): Filesystem     Type      Size  Used Avail Use% Mounted on
upcloud_server.server1 (remote-exec): devtmpfs       devtmpfs  3.8G     0  3.8G   0% /dev
upcloud_server.server1 (remote-exec): tmpfs          tmpfs     3.9G     0  3.9G   0% /dev/shm
upcloud_server.server1 (remote-exec): tmpfs          tmpfs     3.9G   18M  3.8G   1% /run
upcloud_server.server1 (remote-exec): tmpfs          tmpfs     3.9G     0  3.9G   0% /sys/fs/cgroup
upcloud_server.server1 (remote-exec): /dev/vda1      xfs       160G  1.6G  159G   1% /
upcloud_server.server1 (remote-exec): tmpfs          tmpfs     781M     0  781M   0% /run/user/0

upcloud_server.server1 (remote-exec): CentOS Linux release 7.9.2009 (Core)
upcloud_server.server1: Creation complete after 52s [id=0006f04a-15e3-4f4d-83xxx-7cc592935xxx]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## Variable Template Method

Instead of hardcoding `server1.tf` settings, you can use variables outlined at https://upcloud.com/resources/tutorials/terraform-variables via a dedicated `variables.tf` file. Updated with new [Upcloud High CPU and High MEM plans](https://upcloud.com/pricing-2023).

The `variables.tf` file

```
variable "hostname" {
  description = "Server hostname"
  default     = "terraform.example.com"
  type        = string
}

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
```

Which allows you to specify a plan by the pre-defined plan name which in this case is as follows:

```
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
```

# Specific Terraform definition files

For CentOS 7 `centos.tfvars`

```
template = "centos7"
```

For AlmaLinux 8 `almalinux8.tfvars`

```
template = "almalinux8"
```

For Rocky Linux 8 `rockylinux8.tfvars`

```
template = "rockylinux8"
```

For AlmaLinux 9 `almalinux9.tfvars`

```
template = "almalinux9"
```

For Rocky Linux 9 `rockylinux9.tfvars`

```
template = "rockylinux9"
```

You can then utilise these definition files on the command line and set the pre-defined plan name from above and desired hostname and `--var-file` for the OS template name i.e.

```
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file centos.tfvars
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux8.tfvars
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux8.tfvars
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux9.tfvars
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux9.tfvars

terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file centos.tfvars
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux8.tfvars
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux8.tfvars
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux9.tfvars
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux9.tfvars
```

To apply without prompt at `-auto-approve`

```
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file centos.tfvars -auto-approve
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux8.tfvars -auto-approve
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux8.tfvars -auto-approve
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux9.tfvars -auto-approve
terraform apply -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux9.tfvars -auto-approve
```

## plan files

Or save to plan files

```
# save plan files
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file centos.tfvars -out plan20usd-c7
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux8.tfvars -out plan20usd-al8
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux8.tfvars -out plan20usd-rl8
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file almalinux9.tfvars -out plan20usd-al9
terraform plan -var plan="20USD" -var hostname="host.domain.com" --var-file rockylinux9.tfvars -out plan20usd-rl9

# inspect plan files
terraform show "plan20usd-c7"
terraform show "plan20usd-al8"
terraform show "plan20usd-rl8"
terraform show "plan20usd-al9"
terraform show "plan20usd-rl9"

# inspect plan files with debug output prefix with TF_LOG=debug
TF_LOG=debug terraform show "plan20usd-c7"
TF_LOG=debug terraform show "plan20usd-al8"
TF_LOG=debug terraform show "plan20usd-rl8"
TF_LOG=debug terraform show "plan20usd-al9"
TF_LOG=debug terraform show "plan20usd-rl9"

# inspect plan files in json output
terraform show -json "plan20usd-c7"
terraform show -json "plan20usd-al8"
terraform show -json "plan20usd-rl8"
terraform show -json "plan20usd-al9"
terraform show -json "plan20usd-rl9"

# apply plan files
terraform apply "plan20usd-c7"
terraform apply "plan20usd-al8"
terraform apply "plan20usd-rl8"
terraform apply "plan20usd-al9"
terraform apply "plan20usd-rl9"

# apply plan files with debug output prefix with TF_LOG=debug
TF_LOG=debug terraform apply "plan20usd-c7"
TF_LOG=debug terraform apply "plan20usd-al8"
TF_LOG=debug terraform apply "plan20usd-rl8"
TF_LOG=debug terraform apply "plan20usd-al9"
TF_LOG=debug terraform apply "plan20usd-rl9"
```

The `server.tf` file

```
resource "upcloud_server" "server1" {
  # System hostname
  hostname = var.hostname

  # Availability zone
  zone = var.zones["newyork"]

  # Number of CPUs and memory in GB
  plan = var.plans[var.plan]

  metadata = true

  template {
    # System storage device size
    size = lookup(var.storage_sizes, var.plans[var.plan])

    # Template UUID for CentOS 7
    storage = var.templates[var.template]
  }

  # Network interfaces
  network_interface {
    type = "public"
  }

  network_interface {
    type = "utility"
  }

  # Include at least one public SSH key
  login {
    user = var.users[0]
    keys = [
      chomp(file(var.public_key_path))
    ]
    create_password = var.set_password
    password_delivery = "email"
  }

  # Configuring connection details
  connection {
    # The server public IP address
    host        = self.network_interface[0].ip_address
    type        = "ssh"
    user        = var.users[0]
    private_key = file(var.private_key_path)
    script_path = "/home/terraform_%RAND%.sh"
  }

  # Remotely executing a command on the server
  provisioner "remote-exec" {
    inline = [
      "echo 'Hello world!'"
    ]
  }

  user_data = <<-EOF
  export TERM=xterm-256color
  mkdir -p /root
  export HOME=/root
  echo $HOME
  touch $HOME/.rnd
  export RANDFILE=$HOME/.rnd
  chmod 600 $HOME/.rnd
  env
  yum -y update
  EOF

 # Remotely executing a command on the server
  provisioner "remote-exec" {
    inline = [
        "echo",
        "lscpu",
        "echo",
        "free -mlt",
        "echo",
        "df -hT",
        "echo",
        "cat /etc/redhat-release"
    ]
  }
}
```

You can optionally enable backups by adding to `template{}` block

```
  backup_rule {
    interval  = "daily"
    time      = "0100"
    retention = 8
  }
```

## Defining Output Variables

Create an `output.tf` file with your server name defined in `server1.tf` = `server1` as defined by `resource "upcloud_server" "server1" {`

```
output "public_ip" {
  value = upcloud_server.server1.network_interface[0].ip_address
}

output "utility_ip" {
  value = upcloud_server.server1.network_interface[1].ip_address
}

output "hostname" {
  value = upcloud_server.server1.hostname
}

output "plan" {
  value = upcloud_server.server1.plan
}

output "zone" {
  value = upcloud_server.server1.zone
}

output "size" {
  value = upcloud_server.server1.template[0].size
}
```

Then creating a `20USD` plan Upcloud server. You can also add `-var hostname="host.domain.com"` to change the desired hostname.

```
terraform plan -var plan="20USD"
terraform apply -var plan="20USD"
```

To apply without prompt at `-auto-approve`

```
terraform apply -var plan="20USD" -auto-approve
```

```
terraform plan -var plan="20USD"

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # upcloud_server.server1 will be created
  + resource "upcloud_server" "server1" {
      + cpu       = (known after apply)
      + hostname  = "terraform.example.com"
      + id        = (known after apply)
      + mem       = (known after apply)
      + plan      = "2xCPU-4GB"
      + user_data = <<-EOT
            export TERM=xterm-256color
            mkdir -p /home/tftmp
            sleep 5
            chmod 1777 /home/tftmp
            mkdir -p /root
            export HOME=/root
            echo $HOME
            touch $HOME/.rnd
            export RANDFILE=$HOME/.rnd
            chmod 600 $HOME/.rnd
            env
            yum -y update
        EOT
      + zone      = "us-nyc1"

      + login {
          + create_password   = false
          + keys              = [
              + "ssh-rsa XYZABC",
            ]
          + password_delivery = "email"
          + user              = "root"
        }

      + network_interface {
          + bootable            = false
          + ip_address          = (known after apply)
          + ip_address_family   = "IPv4"
          + ip_address_floating = (known after apply)
          + mac_address         = (known after apply)
          + network             = (known after apply)
          + source_ip_filtering = true
          + type                = "public"
        }
      + network_interface {
          + bootable            = false
          + ip_address          = (known after apply)
          + ip_address_family   = "IPv4"
          + ip_address_floating = (known after apply)
          + mac_address         = (known after apply)
          + network             = (known after apply)
          + source_ip_filtering = true
          + type                = "utility"
        }

      + template {
          + address                  = (known after apply)
          + delete_autoresize_backup = false
          + filesystem_autoresize    = false
          + id                       = (known after apply)
          + size                     = 80
          + storage                  = "01000000-0000-4000-8000-000050010300"
          + tier                     = (known after apply)
          + title                    = (known after apply)
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + hostname   = "terraform.example.com"
  + plan       = "2xCPU-4GB"
  + public_ip  = (known after apply)
  + size       = 80
  + utility_ip = (known after apply)
  + zone       = "us-nyc1"

????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

## Viewing User Data Progress

You can check the user data log at `/var/log/upcloud_userdata.log` on the created Upcloud server

```
tail -f /var/log/upcloud_userdata.log
```

Or SSH into the created Upcloud server

```
ssh root@209.xxx.xxx.xxx tail -f /var/log/upcloud_userdata.log
```

# Using upctl Command Line Tool

Use upctl command line tool https://upcloud.com/resources/tutorials/get-started-upcloud-command-line-interface

List servers

```
upctl server list

 UUID                                   Hostname                Plan        Zone      State   
?????????????????????????????????????????????????????????????????????????????????????????????????????????????????? ????????????????????????????????????????????????????????????????????? ????????????????????????????????? ??????????????????????????? ???????????????????????????
 0006f04a-15e3-4f4d-83xxx-7cc592935xxx   terraform.example.com   4xCPU-8GB   us-nyc1   started 
```

Stop server

```
upctl server stop terraform.example.com
```

Start server

```
upctl server start terraform.example.com
```

Show server info

```
upctl server show terraform.example.com
```

```
upctl server show terraform.example.com
  
  Common
    UUID:          0006f04a-15e3-4f4d-83xxx-7cc592935xxx         
    Hostname:      terraform.example.com                        
    Title:         terraform.example.com (managed by terraform) 
    Plan:          4xCPU-8GB                                    
    Zone:          us-nyc1                                      
    State:         started                                      
    Simple Backup: no                                           
    Licence:       0                                            
    Metadata:      False                                        
    Timezone:      UTC                                          
    Host ID:       746718xxxxx                                  
    Tags:                                                       

  Storage: (Flags: B = bootdisk, P = part of plan)

     UUID                                   Title                                  Type   Address    Size (GiB)   Flags 
    ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????? ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????? ?????????????????? ?????????????????????????????? ???????????????????????????????????? ?????????????????????
     01a400de-930e-4cac-8114-62408b5xxxxx   terraform-terraform.example.com-disk   disk   virtio:0          160   P     
    
  NICs: (Flags: S = source IP filtering, B = bootable)

     #   Type      IP Address             MAC Address         Network                                Flags 
    ????????? ??????????????????????????? ?????????????????????????????????????????????????????????????????? ????????????????????????????????????????????????????????? ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????? ?????????????????????
     1   public    IPv4: 209.xxx.xxx.xxx   52:xx:xx:xx:61:5c   034a97cd-e05c-4785-bf33-7648b64xxxxx   S     
     2   utility   IPv4: 10.x.x.xxx        52:xx:xx:xx:be:aa   03243004-e399-49cc-9697-4f5e9fcxxxxx   S  
```

# Deleting Terraform Created Server

```
terraform destroy
```

# Upcloud Region List

```json
{
  "zones": {
    "zone": [
      {
        "description": "Sydney #1",
        "id": "au-syd1",
        "public": "yes"
      },
      {
        "description": "Frankfurt #1",
        "id": "de-fra1",
        "public": "yes"
      },
      {
        "description": "Madrid #1",
        "id": "es-mad1",
        "public": "yes"
      },
      {
        "description": "Helsinki #1",
        "id": "fi-hel1",
        "public": "yes"
      },
      {
        "description": "Helsinki #2",
        "id": "fi-hel2",
        "public": "yes"
      },
      {
        "description": "Amsterdam #1",
        "id": "nl-ams1",
        "public": "yes"
      },
      {
        "description": "Warsaw #1",
        "id": "pl-waw1",
        "public": "yes"
      },
      {
        "description": "Singapore #1",
        "id": "sg-sin1",
        "public": "yes"
      },
      {
        "description": "London #1",
        "id": "uk-lon1",
        "public": "yes"
      },
      {
        "description": "Chicago #1",
        "id": "us-chi1",
        "public": "yes"
      },
      {
        "description": "New York #1",
        "id": "us-nyc1",
        "public": "yes"
      },
      {
        "description": "San Jose #1",
        "id": "us-sjo1",
        "public": "yes"
      }
    ]
  }
}
```

# Upcloud Plan List

```json
{
  "plans": {
    "plan": [
      {
        "core_number": 1,
        "memory_amount": 2048,
        "name": "1xCPU-2GB",
        "public_traffic_out": 2048,
        "storage_size": 50,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 1,
        "memory_amount": 1024,
        "name": "1xCPU-1GB",
        "public_traffic_out": 1024,
        "storage_size": 25,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 2,
        "memory_amount": 4096,
        "name": "2xCPU-4GB",
        "public_traffic_out": 4096,
        "storage_size": 80,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 2,
        "memory_amount": 8192,
        "name": "HIMEM-2xCPU-8GB",
        "public_traffic_out": 2048,
        "storage_size": 100,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 2,
        "memory_amount": 16384,
        "name": "HIMEM-2xCPU-16GB",
        "public_traffic_out": 2048,
        "storage_size": 100,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 4,
        "memory_amount": 65536,
        "name": "HIMEM-4xCPU-64GB",
        "public_traffic_out": 4096,
        "storage_size": 200,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 4,
        "memory_amount": 32768,
        "name": "HIMEM-4xCPU-32GB",
        "public_traffic_out": 4096,
        "storage_size": 100,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 4,
        "memory_amount": 8192,
        "name": "4xCPU-8GB",
        "public_traffic_out": 5120,
        "storage_size": 160,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 6,
        "memory_amount": 16384,
        "name": "6xCPU-16GB",
        "public_traffic_out": 6144,
        "storage_size": 320,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 6,
        "memory_amount": 131072,
        "name": "HIMEM-6xCPU-128GB",
        "public_traffic_out": 6144,
        "storage_size": 300,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 8,
        "memory_amount": 12288,
        "name": "HICPU-8xCPU-12GB",
        "public_traffic_out": 4096,
        "storage_size": 100,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 8,
        "memory_amount": 16384,
        "name": "HICPU-8xCPU-16GB",
        "public_traffic_out": 4096,
        "storage_size": 200,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 8,
        "memory_amount": 196608,
        "name": "HIMEM-8xCPU-192GB",
        "public_traffic_out": 8192,
        "storage_size": 400,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 8,
        "memory_amount": 32768,
        "name": "8xCPU-32GB",
        "public_traffic_out": 7168,
        "storage_size": 640,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 12,
        "memory_amount": 262144,
        "name": "HIMEM-12xCPU-256GB",
        "public_traffic_out": 10240,
        "storage_size": 500,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 12,
        "memory_amount": 49152,
        "name": "12xCPU-48GB",
        "public_traffic_out": 9216,
        "storage_size": 960,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 16,
        "memory_amount": 24576,
        "name": "HICPU-16xCPU-24GB",
        "public_traffic_out": 5120,
        "storage_size": 100,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 16,
        "memory_amount": 393216,
        "name": "HIMEM-16xCPU-384GB",
        "public_traffic_out": 12288,
        "storage_size": 600,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 16,
        "memory_amount": 32768,
        "name": "HICPU-16xCPU-32GB",
        "public_traffic_out": 5120,
        "storage_size": 200,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 16,
        "memory_amount": 65536,
        "name": "16xCPU-64GB",
        "public_traffic_out": 10240,
        "storage_size": 1280,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 20,
        "memory_amount": 131072,
        "name": "20xCPU-128GB",
        "public_traffic_out": 24576,
        "storage_size": 2048,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 20,
        "memory_amount": 98304,
        "name": "20xCPU-96GB",
        "public_traffic_out": 12288,
        "storage_size": 1920,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 32,
        "memory_amount": 49152,
        "name": "HICPU-32xCPU-48GB",
        "public_traffic_out": 6144,
        "storage_size": 200,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 32,
        "memory_amount": 65536,
        "name": "HICPU-32xCPU-64GB",
        "public_traffic_out": 6144,
        "storage_size": 300,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 64,
        "memory_amount": 131072,
        "name": "HICPU-64xCPU-128GB",
        "public_traffic_out": 7168,
        "storage_size": 300,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 64,
        "memory_amount": 98304,
        "name": "HICPU-64xCPU-96GB",
        "public_traffic_out": 7168,
        "storage_size": 200,
        "storage_tier": "maxiops"
      }
    ]
  }
}
```

# OS Template Storage UUID

```json
{
  "storages": {
    "storage": [
      {
        "access": "public",
        "license": 3.36,
        "size": 28,
        "state": "online",
        "template_type": "native",
        "title": "Windows Server 2016 Datacenter",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000010060200"
      },
      {
        "access": "public",
        "license": 0.694,
        "size": 29,
        "state": "online",
        "template_type": "native",
        "title": "Windows Server 2016 Standard",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000010060300"
      },
      {
        "access": "public",
        "license": 3.36,
        "size": 25,
        "state": "online",
        "template_type": "native",
        "title": "Windows Server 2019 Datacenter",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000010070200"
      },
      {
        "access": "public",
        "license": 0.694,
        "size": 25,
        "state": "online",
        "template_type": "native",
        "title": "Windows Server 2019 Standard",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000010070300"
      },
      {
        "access": "public",
        "license": 3.36,
        "size": 18,
        "state": "online",
        "template_type": "native",
        "title": "Windows Server 2022 Datacenter",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000010080200"
      },
      {
        "access": "public",
        "license": 0.694,
        "size": 18,
        "state": "online",
        "template_type": "native",
        "title": "Windows Server 2022 Standard",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000010080300"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "Debian GNU/Linux 9 (Stretch)",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000020040100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "Debian GNU/Linux 10 (Buster)",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000020050100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "Debian GNU/Linux 11 (Bullseye)",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000020060100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 4,
        "state": "online",
        "template_type": "native",
        "title": "Ubuntu Server 18.04 LTS (Bionic Beaver)",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000030080200"
      },
      {
        "access": "public",
        "license": 0,
        "size": 4,
        "state": "online",
        "template_type": "native",
        "title": "Ubuntu Server 20.04 LTS (Focal Fossa)",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000030200200"
      },
      {
        "access": "public",
        "license": 0,
        "size": 4,
        "state": "online",
        "template_type": "cloud-init",
        "title": "Ubuntu Server 22.04 LTS (Jammy Jellyfish)",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000030220200"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "CentOS 7",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000050010300"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "CentOS 8",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000050010400"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "CentOS Stream 8",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000050010500"
      },
      {
        "access": "public",
        "license": 0,
        "size": 5,
        "state": "online",
        "template_type": "native",
        "title": "CentOS Stream 9",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000050010600"
      },
      {
        "access": "public",
        "license": 0,
        "size": 5,
        "state": "online",
        "template_type": "native",
        "title": "Plesk Obsidian",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000130010100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "AlmaLinux 8",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000140010100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 4,
        "state": "online",
        "template_type": "cloud-init",
        "title": "AlmaLinux 9",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000140020100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "Rocky Linux 8",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000150010100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 4,
        "state": "online",
        "template_type": "cloud-init",
        "title": "Rocky Linux 9",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000150020100"
      },
      {
        "access": "public",
        "license": 0,
        "size": 5,
        "state": "online",
        "template_type": "cloud-init",
        "title": "UpCloud K8s",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000160010100"
      }
    ]
  }
}
```
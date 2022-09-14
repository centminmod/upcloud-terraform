# Upcloud Terraform Based Server Installation

Terraform based server install at Upcloud using guide outlined at https://upcloud.com/resources/tutorials/get-started-terraform & https://www.terraform.io/downloads

* [Install Terraform](#install-terraform)
* [Setup Upcloud API Credentials](#setup-upcloud-api-credentials)
* [Initialize New Terraform Project](#initialize-new-terraform-project)
* [Planning Infrastructure With Terraform](#planning-infrastructure-with-terraform)
  * [Viewing User Data Progress](#viewing-user-data-progress)
* [Using upctl Command Line Tool](#using-upctl-command-line-tool)
* [Deleting Terraform Created Server](#deleting-terraform-created-server)

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
#upctl completion bash > /etc/bash_completion.d/upctl
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

```
touch server1.tf
```

Using values from https://developers.upcloud.com/1.3/ and https://upcloud.com/resources/tutorials/reduce-downtime-terraform-redeployments

Using:

* zone = `us-nyc1` [list of regions](#region-list)
* plan = `4xCPU-8GB` [list of plans](#plan-list)
* storage template [list of OS storage templete UUIDs](#os-template-storage-uuid)
  * for CentOS 7 UUID = `01000000-0000-4000-8000-000050010300` with size = `160GB`
  * for AlmaLinux 8 UUID = `01000000-0000-4000-8000-000140010100` with size = `160GB`
  * for Rocky Linux 8 UUID = `01000000-0000-4000-8000-000150010100` with size = `160GB`

```
resource "upcloud_server" "server1" {
  # System hostname
  hostname = "terraform.example.com"

  # Availability zone
  zone = "us-nyc1"

  # Number of CPUs and memory in GB
  plan = "4xCPU-8GB"

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
      "ssh-rsa XYZABC",
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
  }

  # Remotely executing a command on the server
  provisioner "remote-exec" {
    inline = [
      "echo 'Hello world!'"
    ]
  }

  user_data = <<EOF
  export TERM=xterm-256color
  yum -y update
  curl -sL https://github.com/centminmod/scriptreplay/raw/master/script-record.sh -o /usr/local/bin/script-record
  chmod +x /usr/local/bin/script-record
  EOF
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
              yum -y update
              curl -sL https://github.com/centminmod/scriptreplay/raw/master/script-record.sh -o /usr/local/bin/script-record
              chmod +x /usr/local/bin/script-record          
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
upcloud_server.server1 (remote-exec): Hello world!
upcloud_server.server1: Creation complete after 52s [id=0006f04a-15e3-4f4d-83xxx-7cc592935xxx]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## Viewing User Data Progress

Check user data installed [script-record script](https://github.com/centminmod/scriptreplay) was setup

```
script-record

Usage:

/usr/local/bin/script-record rec SESSION_NAME
/usr/local/bin/script-record play /path/to/cmds.gz /path/to/time.txt.gz
/usr/local/bin/script-record play /path/to/cmds.gz /path/to/time.txt.gz 2
/usr/local/bin/script-record play-nogz /path/to/cmds /path/to/time.txt
/usr/local/bin/script-record play-nogz /path/to/cmds /path/to/time.txt 2
/usr/local/bin/script-record list
```

You can check the user date log at `/var/log/upcloud_userdata.log` on the created Upcloud server

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
────────────────────────────────────── ─────────────────────── ─────────── ───────── ─────────
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
    ────────────────────────────────────── ────────────────────────────────────── ────── ────────── ──────────── ───────
     01a400de-930e-4cac-8114-62408b5xxxxx   terraform-terraform.example.com-disk   disk   virtio:0          160   P     
    
  NICs: (Flags: S = source IP filtering, B = bootable)

     #   Type      IP Address             MAC Address         Network                                Flags 
    ─── ───────── ────────────────────── ─────────────────── ────────────────────────────────────── ───────
     1   public    IPv4: 209.xxx.xxx.xxx   52:xx:xx:xx:61:5c   034a97cd-e05c-4785-bf33-7648b64xxxxx   S     
     2   utility   IPv4: 10.x.x.xxx        52:xx:xx:xx:be:aa   03243004-e399-49cc-9697-4f5e9fcxxxxx   S  
```

# Deleting Terraform Created Server

```
terraform destroy
```

# Region List

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

# Plan List

```json
{
  "plans": {
    "plan": [
      {
        "core_number": 1,
        "memory_amount": 1024,
        "name": "1xCPU-1GB",
        "public_traffic_out": 1024,
        "storage_size": 25,
        "storage_tier": "maxiops"
      },
      {
        "core_number": 1,
        "memory_amount": 2048,
        "name": "1xCPU-2GB",
        "public_traffic_out": 2048,
        "storage_size": 50,
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
        "core_number": 8,
        "memory_amount": 32768,
        "name": "8xCPU-32GB",
        "public_traffic_out": 7168,
        "storage_size": 640,
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
        "size": 3,
        "state": "online",
        "template_type": "native",
        "title": "Rocky Linux 8",
        "type": "template",
        "uuid": "01000000-0000-4000-8000-000150010100"
      }
    ]
  }
}
```
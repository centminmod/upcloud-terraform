resource "upcloud_server" "server1" {
  # System hostname
  hostname = "terraform.example.com"

  # Availability zone
  zone = var.zones["newyork"]

  # Number of CPUs and memory in GB
  plan = var.plans[var.plan]

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
      file(var.public_key_path)
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
  curl -sL https://github.com/centminmod/scriptreplay/raw/master/script-record.sh -o /usr/local/bin/script-record
  chmod +x /usr/local/bin/script-record
  EOF
}
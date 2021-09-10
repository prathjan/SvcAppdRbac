#get the data fro the global vars WS
data "terraform_remote_state" "appvm" {
  backend = "remote"
  config = {
    organization = var.org 
    workspaces = {
      name = var.appvmwsname
    }
  }
}

data "terraform_remote_state" "saasvm" {
  backend = "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.saaswsname
    }
  }
}

data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.globalwsname
    }
  }
}

variable "org" {
  type = string
}
variable "appvmwsname" {
  type = string
}

variable "saaswsname" {
  type = string
}

variable "globalwsname" {
  type = string
}

resource "null_resource" "vm_node_init" {
  provisioner "file" {
    source = "scripts/"
    destination = "/tmp"
    connection {
      type = "ssh"
      host = "${local.appvmip}"
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/rbac.sh",
        "${local.download}",
        "/tmp/rbac.sh ${local.nbrapm} ${local.nbrma} ${local.nbrsim} ${local.nbrnet}",
        ". /home/ec2-user/environment/workshop/application.env",
        "echo echoing install",
        "echo ${local.install}",
        "echo echoing accesskey",
        "echo $APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY",
        "echo replacement",
        "echo ${local.install} > /tmp/installcmd.sh",
        "sed 's/fillmein/'$APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY'/g' /tmp/installcmd.sh > /tmp/installexec.sh",
	"/opt/appdynamics/zeroagent/bin/zeroctl uninstall",
	"rm -rf /opt/appdynamics/zeroagent",
        "chmod +x /tmp/installexec.sh",
        "echo installing",
        "/tmp/installexec.sh",
    ]
    connection {
      type = "ssh"
      host = "${local.appvmip}" 
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }
}


locals {
  appvmip = data.terraform_remote_state.appvm.outputs.vm_ip[0]
  download = yamldecode(data.terraform_remote_state.saasvm.outputs.download)
  install = yamldecode(data.terraform_remote_state.saasvm.outputs.install)  
  nbrapm = data.terraform_remote_state.global.outputs.nbrapm
  nbrma = data.terraform_remote_state.global.outputs.nbrma
  nbrsim = data.terraform_remote_state.global.outputs.nbrsim
  nbrnet = data.terraform_remote_state.global.outputs.nbrnet
  root_password = yamldecode(data.terraform_remote_state.global.outputs.root_password)
}


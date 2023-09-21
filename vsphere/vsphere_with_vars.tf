provider "vsphere" {
  # If you use a domain, set your login like this "Domain\\User"
  user           = "vsphere_user"
  password       = "Sup3rS3cr3tP@ssw0rd"
  vsphere_server = "192.168.100.10"

  # If you have a self-signed cert
  allow_unverified_ssl = true
  api_timeout	 = 30
}

data "vsphere_datacenter" "dc" {
  name = "DCNAME"
}

# If you don't have any resource pools, put "/Resources" after cluster name
data "vsphere_resource_pool" "pool" {
  name          = var.resource-pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve datastore information on vsphere
data "vsphere_datastore" "datastore" {
  name          = var.vm-datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}


# Retrieve network information on vsphere
data "vsphere_network" "network" {
  name		 = var.vm_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve template information on vsphere
data "vsphere_virtual_machine" "template" {
  name          = var.template
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Variable Section
variable "vm-datastore" {
  type        = string
  description = "Datastore used for the vSphere virtual machines"
}

variable "linux_hostname" {
  type = string
  description = "Choose a hostname"
}

variable "template"{
  type = string
  description = <<EOF
    template1name
    template2name
    template3name
    template4name
  EOF
}

variable "vm_network" {
  type = string
  description = "Choose a network. Ex. 'VLAN###'"
}

variable "vm_cpu" {
  type = string
  description = "Number of vCPU for the VM"
#  default = "2"
}

variable "vm_ram" {
  type = string
  description = "Amount of RAM for the VM (example: 2048, 4096, 8192, 12288, 16384) in MB"
}

variable "resource-pool" {
  type = string
  description = "Resource pool name"
}

variable "folder-name" {
  type = string
  description = "Folder name (example: folderName"
}

variable "disk-size" {
  type = string
  description = "VM disk size (example: 60, 75, 100) in GB"
}

# Set vm parameters
resource "vsphere_virtual_machine" "demo" {
  name             = var.linux_hostname
  num_cpus         = var.vm_cpu
  memory           = var.vm_ram
  folder           = "folder/${var.folder-name}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type


    # Set network parameters
    network_interface {
      network_id = data.vsphere_network.network.id
    }

  # Use a predefined vmware template as main disk
  disk {
    label = "vm-one.vmdk"
    size = var.disk-size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.linux_hostname
        domain    = "dev.domain.com"
      }

      network_interface {}

      ipv4_gateway = ""
    }
  }

  # Execute script on remote vm after this creation
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "user"
      password = "password"
      host     = vsphere_virtual_machine.demo.default_ip_address
    }
    inline = [
      "sudo bash -c \"$(curl -fsSL ipaddress:80/script.sh)\"",
      "sudo chage --expiredate $(date -d +14days +%Y-%m-%d) user"
    ]
  }
}

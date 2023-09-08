provider "vsphere" {
  # If you use a domain, set your login like this "Domain\\User"
  user           = "vsphere_user"
  password       = "Sup3rS3cr3tP@ssw0rd"
  vsphere_server = "192.168.100.10"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "DCNAME"
}

# If you don't have any resource pools, put "/Resources" after cluster name
data "vsphere_resource_pool" "pool" {
  name          = "RP_NAME"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve datastore information on vsphere
data "vsphere_datastore" "datastore" {
  name          = "datastoreName"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve network information on vsphere
data "vsphere_network" "network" {
  name          = "VLAN###"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve template information on vsphere
data "vsphere_virtual_machine" "template" {
  name          = "templateName"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Set vm parameters
resource "vsphere_virtual_machine" "demo" {
  name             = "machineName"
  num_cpus         = 2
  memory           = 4096
  folder           = "folder/path"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  #  # Set network parameters
  #  network_interface {
  #    network_id = data.vsphere_network.network.id
  #  }

  # Use a predefined vmware template as main disk
  disk {
    label = "vm-one.vmdk"
    size  = "65"
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "machineName"
        domain    = "corporate.domain.com"
      }

      # Empty from DHCP scope
      network_interface {}

# Assign a static network:
#     network_interface {
#       ipv4_address = "192.168.240.170"
#       ipv4_netmask = "24"
#       dns_server_list = ["192.168.240.28", "192.168.240.29"]
#     }

      ipv4_gateway = ""
    }
  }

#  # Execute script on remote vm after this creation
#  provisioner "remote-exec" {
#    script = "scripts/example-script.sh"
#    connection {
#      type     = "ssh"
#      user     = "root"
#      password = "VMware1!"
#      host     = vsphere_virtual_machine.demo.default_ip_address
#    }
#  }
}

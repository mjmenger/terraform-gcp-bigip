# BIG-IP


locals {
  vm_onboard = templatefile("${path.module}/onboard.tpl", {
      uname          = var.uname
      usecret        = var.usecret
      ksecret        = var.ksecret
      gcp_project_id = var.gcp_project_id
      DO_URL         = var.DO_URL
      AS3_URL        = var.AS3_URL
      TS_URL         = var.TS_URL
      onboard_log    = var.onboard_log
    })
}

# Create F5 BIG-IP VMs
resource "google_compute_instance" "f5vm" {
  name           = var.host_name
  machine_type   = var.bigipMachineType
  zone           = var.zone
  can_ip_forward = true

  tags = var.tags

  boot_disk {
    initialize_params {
      image = var.customImage != "" ? var.customImage : var.image_name
      size  = "128"
    }
  }

  network_interface {
    network    = var.ext_vpc
    subnetwork = var.ext_subnet
    access_config {}
    alias_ip_range {
      ip_cidr_range = var.ext_alias_ip_cidr
    }
  }

  network_interface {
    network    = var.mgmt_vpc
    subnetwork = var.mgmt_subnet
    access_config {}
  }

  network_interface {
    network    = var.int_vpc
    subnetwork = var.int_subnet
  }

  metadata = {
    ssh-keys               = "${var.uname}:${var.ssh_public_key}"
    block-project-ssh-keys = true
    startup-script         = var.customImage != "" ? var.customUserData : local.vm_onboard
  }

  service_account {
    email  = var.svc_acct
    scopes = ["cloud-platform"]
  }
}


# A dedicated service account for this VM, instead of the wide-permission default Compute
# Engine service account. The whole point: if this VM is ever compromised, the blast radius
# is "can push images and nothing else", not "can touch every resource in the project".
resource "google_service_account" "vm" {
  project      = var.project_id
  account_id   = "${var.name}-sa"
  display_name = "Service account for ${var.name}"
}

resource "google_project_iam_member" "vm_registry_writer" {
  project = var.project_id
  role    = var.registry_reader_role
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_compute_address" "static_ip" {
  project = var.project_id
  name    = "${var.name}-ip"
  region  = var.region
}

resource "google_compute_instance" "vm" {
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type

  tags = ["ssh", "jenkins"] # matches target_tags on the firewall rules in the network module

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30 # GB; Docker images and Jenkins jobs eat disk fast, default 10GB is too small
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"] # broad OAuth scope; the actual permission boundary is the IAM role above, not this
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  # Prevents `terraform destroy` from accidentally nuking this VM without an explicit
  # override. Remove this line (or set to false) when you actually intend to destroy it.
  # For a lab this may be more friction than it's worth; keep it if you'd rather be safe.
  # deletion_protection = true
}

# Custom-mode VPC: no auto-created subnets in every region, we declare exactly what we need.
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  project       = var.project_id
  name          = "${var.network_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr

  # Secondary ranges, unused until Phase 7, but reserved now so GKE can be added later
  # without recreating this subnet (which would also recreate anything attached to it).
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.gke_services_cidr
  }
}

# Deny-by-default is implicit in GCP VPCs: nothing is reachable unless a firewall rule
# explicitly allows it. Everything below is an explicit exception, kept as narrow as possible.

resource "google_compute_firewall" "allow_ssh" {
  project = var.project_id
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_ip] # only you, never 0.0.0.0/0
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_jenkins" {
  project = var.project_id
  name    = "${var.network_name}-allow-jenkins"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.allowed_ssh_ip]
  target_tags   = ["jenkins"]
}

# Lets VMs with no external IP still reach the internet (apt, docker pulls, etc.), and lets
# a VM's outbound connections work even before we bother giving it a public IP.
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

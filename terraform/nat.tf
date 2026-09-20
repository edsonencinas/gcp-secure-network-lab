resource "google_compute_router" "router" {
  name    = "secure-network-router"
  region  = var.region
  network = google_compute_network.main.id

  bgp {
    asn = 65001
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "secure-network-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.app.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  subnetwork {
    name                    = google_compute_subnetwork.web.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
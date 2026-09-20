resource "google_compute_instance_template" "web" {
  name_prefix  = "web-template-"
  machine_type = "e2-micro"

  lifecycle {
    create_before_destroy = true
  }

  tags = ["web-server", "iap-ssh"]

  service_account {
    email  = google_service_account.web.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.web.id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash

    apt-get update
    apt-get install -y nginx

    systemctl enable nginx
    systemctl start nginx

    hostname=$(hostname)
    echo "<h1>GCP Web Server: $hostname</h1>" > /var/www/html/index.html
  EOF
}

resource "google_compute_instance_group_manager" "web" {
  name               = "web-instance-group"
  base_instance_name = "web"
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.web.id
  }

  target_size = 2

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "web" {
  name = "web-health-check"

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "web" {
  name                  = "web-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [
    google_compute_health_check.web.id
  ]

  backend {
    group = google_compute_instance_group_manager.web.instance_group
  }
}

resource "google_compute_global_address" "web_lb" {
  name = "web-lb-ip"
}

resource "google_compute_url_map" "web_lb" {
  name            = "web-lb-url-map"
  default_service = google_compute_backend_service.web.id
}

resource "google_compute_target_http_proxy" "web_lb" {
  name    = "web-lb-http-proxy"
  url_map = google_compute_url_map.web_lb.id
}

resource "google_compute_global_forwarding_rule" "web_lb" {
  name                  = "web-lb-forwarding-rule"
  target                = google_compute_target_http_proxy.web_lb.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.web_lb.id
}
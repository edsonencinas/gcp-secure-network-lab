# Architecture

## Overview

The GCP Secure Network Lab uses a segmented VPC with private web and application servers. Terraform manages the core infrastructure.

![diagrams](architecture.png)

```text
                         Internet
                            │
                            ▼
                Global External HTTP
                   Load Balancer
                            │
                            ▼
                 ┌──────────────────┐
                 │   Web MIG        │
                 │                  │
                 │  Web VM 1        │
                 │  Web VM 2        │
                 │  Private IPs     │
                 └────────┬─────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
              ▼                       ▼
        App Subnet               Cloud NAT
        10.10.20.0/24                 │
              │                       ▼
              ▼                    Internet
         App Server
         Private IP


              ┌──────────────────────────────┐
              │        secure-network        │
              │            VPC               │
              │                              │
              │ Web: 10.10.10.0/24           │
              │ App: 10.10.20.0/24           │
              │ Mgmt: 10.10.30.0/24          │
              └──────────────────────────────┘

        IAP SSH • Firewall • VPC Flow Logs • IAM
```

## Main Components

| Component                 | Purpose                                     |
| ------------------------- | ------------------------------------------- |
| Custom VPC                | Isolated network environment                |
| Web subnet                | Hosts private web VMs                       |
| App subnet                | Hosts private application server            |
| Management subnet         | Reserved for management resources           |
| Managed Instance Group    | Maintains two web instances                 |
| Global HTTP Load Balancer | Public entry point and traffic distribution |
| Cloud NAT                 | Outbound internet access for private VMs    |
| Cloud Router              | Supports Cloud NAT                          |
| IAP                       | Secure SSH access to private VMs            |
| Firewall                  | Controls network traffic                    |
| VPC Flow Logs             | Network visibility                          |
| IAM / Service Account     | Workload permissions                        |
| Cloud Monitoring          | Infrastructure monitoring                   |

## Network Flow

### Inbound

```text
Internet
   ↓
Load Balancer
   ↓
Web MIG
   ↓
Private Web VM
```

### Outbound

```text
Private VM
   ↓
Cloud NAT
   ↓
Internet
```

### Administration

```text
Administrator
   ↓
IAP
   ↓
Private VM
```

## Security

The architecture uses:

- Private IPs for web and application VMs
- IAP instead of public SSH access
- VPC firewall rules
- Cloud NAT for outbound connectivity
- VPC Flow Logs
- Dedicated service account
- IAM permissions
- Load-balancer health checks

## High Availability

The web tier uses a Managed Instance Group with two instances behind the global external HTTP load balancer.

The load balancer performs HTTP health checks on port 80 and sends traffic only to healthy backends.

The current MIG is deployed in a **single zone (`us-central1-a`)**, so multi-zone high availability is not yet implemented.

## Terraform

Core infrastructure is managed with Terraform:

```text
terraform/
├── versions.tf
├── main.tf
├── variables.tf
├── network.tf
├── firewall.tf
├── nat.tf
├── compute.tf
├── load-balancer.tf
└── iam.tf
```

The Cloud Monitoring dashboard is currently configured manually in Google Cloud.

## Key Troubleshooting

During deployment, the load balancer initially reported:

```text
no healthy upstream
```

The MIG instances were unable to install Nginx because they had no outbound connectivity during startup.

The root cause was that the web subnet had not yet been included in Cloud NAT.

After adding the subnet to Cloud NAT, the MIG instances were replaced so the startup script could run again. The new instances installed Nginx and successfully passed the load-balancer health check.

## Current Architecture Limitations

- Single-zone MIG
- HTTP only
- No Cloud Armor
- No autoscaling
- No database tier
- Monitoring dashboard not yet managed by Terraform
- Terraform remote state not configured

# GCP Secure Network Lab

> Secure, segmented, and highly available Google Cloud infrastructure deployed with using Terraform.

This is a hands-on Google Cloud project demonstrating skills on **cloud networking, infrastructure as code, network security, load balancing, high availability, monitoring, and troubleshooting**.

I designed an environment that will simulate a small pruduction-style web application using a custom VPC, private subnets, Managed Instance Group (MIG), Cloud NAT, Identity-Aware Proxy (IAP), firewall, VPC Flow Logs and an external HTTP Load Balancer.

---

## The Architecture

```text
                         Internet
                            │
                            ▼
              ┌──────────────────────────┐
              │ Global External HTTP LB  │
              │      Public IP :80       │
              └────────────┬─────────────┘
                           │
                           ▼
              ┌──────────────────────────┐
              │   Web Managed Instance   │
              │         Group            │
              │                          │
              │   ┌──────┐   ┌──────┐    │
              │   │ Web  │   │ Web  │    │
              │   │ VM 1 │   │ VM 2 │    │
              │   └──────┘   └──────┘    │
              │    Private IPs only      │
              └────────────┬─────────────┘
                           │
                           │ Cloud NAT
                           ▼
                      ┌───────────┐
                      │ Internet  │
                      └───────────┘


        ┌──────────────────────────────────────────┐
        │              Custom VPC                  │
        │            secure-network                │
        │                                          │
        │  ┌────────────────────────────────────┐  │
        │  │ Web Subnet                         │  │
        │  │ 10.10.10.0/24                      │  │
        │  │                                    │  │
        │  │ Web MIG / Private Web VMs          │  │
        │  └────────────────────────────────────┘  │
        │                                          │
        │  ┌────────────────────────────────────┐  │
        │  │ App Subnet                         │  │
        │  │ 10.10.20.0/24                      │  │
        │  │                                    │  │
        │  │ Private App Server                 │  │
        │  └────────────────────────────────────┘  │
        │                                          │
        │  ┌────────────────────────────────────┐  │
        │  │ Management Subnet                  │  │
        │  │ 10.10.30.0/24                      │  │
        │  └────────────────────────────────────┘  │
        │                                          │
        │  Firewall │ Flow Logs │ IAP │ NAT        │
        └──────────────────────────────────────────┘
```

---

## Project Objectives

The objective of this project was to demonstrate practical experiences with:

- Google Cloud networking
- Custom VPC design
- Network segmentation
- Private VM architecture
- Infrastructure as Code
- Terraform
- Managed Instance Groups
- External HTTP Load Balancing
- Cloud NAT
- Identity-Aware Proxy (IAP)
- Firewall rules
- VPC Flow Logs
- IAM and service accounts
- Cloud Monitoring
- Cloud troubleshooting
- High availability
- Secure cloud architecture

---

## Technologies

| Technology                         | Purpose                                  |
| ---------------------------------- | ---------------------------------------- |
| Google Cloud Platform              | Cloud infrastructure                     |
| Compute Engine                     | Virtual machines                         |
| Custom VPC                         | Network architecture                     |
| Terraform                          | Infrastructure as Code                   |
| Managed Instance Group             | VM scalability and availability          |
| Global External HTTP Load Balancer | Traffic distribution                     |
| Cloud NAT                          | Outbound internet access for private VMs |
| IAP                                | Secure administrative SSH access         |
| VPC Firewall                       | Network access control                   |
| VPC Flow Logs                      | Network visibility                       |
| Cloud Monitoring                   | Infrastructure monitoring                |
| IAM                                | Identity and access management           |
| Nginx                              | Web server                               |
| Debian 12                          | VM operating system                      |
| Cloud Shell                        | Infrastructure deployment                |

---

# Infrastructure

## VPC

A custom-mode VPC named:

```text
secure-network
```

The VPC uses regional routing and manually defined subnets rather than auto generated subnets.

### Subnets

| Subnet              | CIDR            | Purpose              |
| ------------------- | --------------- | -------------------- |
| `web-subnet`        | `10.10.10.0/24` | Web tier             |
| `app-subnet`        | `10.10.20.0/24` | Application tier     |
| `management-subnet` | `10.10.30.0/24` | Management resources |

## To provide network visibility, I enabled VPC Flow logs on the web and application subnets.

# Network Security

This project uses multiple layers of network security.

## Firewall Rules

### HTTP

```text
allow-http
```

Allows TCP port 80 traffic to instances tagged:

```text
web-server
```

### Internal Traffic

```text
allow-internal
```

Allows internal TCP, UDP, and ICMP communication from:

```text
10.10.0.0/16
```

### IAP SSH

```text
allow-iap-ssh
```

Allows SSH access only from the Google IAP TCP forwarding range:

```text
35.235.240.0/20
```

Instances that requires administrative access are tagged:

```text
iap-ssh
```

This approach avoids exposing SSH directly to the public internet.

---

# Private Web Infrastructure

The web servers are deployed using a **Managed Instance Group (MIG)**.

```text
web-instance-group
```

The MIG maintains:

```text
Target size: 2 instances
Zone: us-central1-a
```

The instances:

- Run Debian 12
- Install Nginx through a startup script
- Have private IP addresses
- Do NOT have external IP addresses
- Are protected by firewall rules
- Are monitored through Cloud Monitoring
- Are behind the external load balancer

---

# Load Balancing

The project uses a **Global External HTTP Load Balancer**.

Traffic flow:

```text
Client
  │
  ▼
Global External HTTP Load Balancer
  │
  ▼
Backend Service
  │
  ▼
Managed Instance Group
  │
  ├── Web VM 1
  └── Web VM 2
```

The load balancer uses an HTTP health check:

```text
web-health-check
```

with:

```text
Protocol: HTTP
Port: 80
Path: /
```

## Only instances with HEALTHY status receive traffic.

# Cloud NAT

For outbound internet connectivity, the web and application subnets uses **Cloud NAT**.

```text
secure-network-router
        │
        ▼
secure-network-nat
```

Using Cloud NAT, it allows private VMs to:

- Download operating-system packages
- Install necessary software
- Access external APIs
- Reach the internet for required outbound connections

without the need of public IP addresses to the VMs.

The web and application subnets are configured for NAT.

---

# Secure Administration with IAP

To provide an SSH access, **Identity-Aware Proxy (IAP)** was used instead of exposing port 22 to the public internet.

Traffic flow:

```text
Administrator
      │
      ▼
Google IAP
      │
      ▼
Private VM
```

Firewall access is restricted to:

```text
35.235.240.0/20
```

## This approach provides more secure administrative access model than assigning public IP addresses to internal servers.

# IAM

The web infrastructure uses a dedicated service account:

```text
web-server-sa
```

A minimum required logging permission is granted to this service account:

```text
roles/logging.logWriter
```

This demonstrates the use of a dedicated workload identity than relying on broad permissions.

---

# Monitoring

A Cloud Monitoring dashboard was created to provide analytics & visibility to the entire infrastructure.

The dashboard includes metrics for:

### Web MIG

- CPU utilization

### Application Server

- CPU utilization
- Network received bytes
- Network sent bytes

### Load Balancer

- Request count
- Backend request count

These metrics provide visibility into:

```text
Compute utilization
        +
Network activity
        +
Load balancer traffic
        +
Backend traffic
```

Simmulated traffic was generated against the load balancer to test that the metrics respond to actual workload activity.

---

# VPC Flow Logs

VPC Flow Logs are enabled on the web and application subnets.

Configuration:

```text
Aggregation interval: 5 seconds
Flow sampling: 50%
Metadata: INCLUDE_ALL_METADATA
```

The Flow Logs provided visibility into network traffic and can help with:

- Network troubleshooting
- Security investigations
- Traffic analysis
- Connectivity validation
- Identifying unexpected communication patterns

---

# Infrastructure as Code

The infrastructure is managed using Terraform rather than manual creation of the resources through Google Cloud Console.

Example Terraform structure:

```text
terraform/
├── versions.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── network.tf
├── firewall.tf
├── nat.tf
├── compute.tf
├── load-balancer.tf
├── iam.tf
└── monitoring.tf
```

Terraform provides:

- Repeatable deployments
- Version-controlled infrastructure
- Consistent configuration
- Easier infrastructure changes
- Infrastructure documentation through code

---

# Deployment

## Prerequisites

The following are needed:

- A Google Cloud account
- A Google Cloud project
- Google Cloud SDK
- Terraform
- Appropriate GCP permissions

Authenticate with Google Cloud:

```bash
gcloud auth login
```

Set the project:

```bash
gcloud config set project gcp-secure-network-lab
```

Initialize Terraform:

```bash
terraform init
```

Review the planned infrastructure:

```bash
terraform plan
```

Deploy:

```bash
terraform apply
```

Confirm the deployment when prompted.

---

# Validation

After the deployment, the following areas can be validated.

## 1. Load Balancer

Retrieve the asigned load balancer IP and test:

```bash
curl http://<LOAD_BALANCER_IP>
```

Expected response:

```html
<h1>GCP Web Server: <hostname></h1>
```

Using the following code, repeated requests can demonstrate backend distribution:

```bash
for i in {1..10}; do
  curl -s http://<LOAD_BALANCER_IP>
  echo
done
```

---

## 2. Generate Load Balancer Traffic

Generate requests for monitoring validation:

```bash
for i in {1..200}; do
  curl -s http://<LOAD_BALANCER_IP> > /dev/null
done
```

Or continuously generate traffic:

```bash
while true; do
  curl -s http://<LOAD_BALANCER_IP> > /dev/null
  sleep 1
done
```

The Cloud Monitoring dashboard should show load-balancer activity.

---

## 3. MIG

Check the managed instance group:

```bash
gcloud compute instance-groups managed list
```

Inspect the instances:

```bash
gcloud compute instance-groups managed list-instances \
  web-instance-group \
  --zone=us-central1-a
```

---

## 4. IAP SSH

Connect to the private application server through IAP:

```bash
gcloud compute ssh app-server \
  --zone=us-central1-a \
  --tunnel-through-iap
```

The application server does NOT require a public IP.

---

## 5. Cloud NAT

From the private application server, test the outbound connectivity:

```bash
curl https://www.google.com
```

This will confirm that the private VM can access the internet through Cloud NAT.

---

# Troubleshooting Case Study

## Problem

During initial deployment, the external load balancer returned:

```text
no healthy upstream
```

The backend instances were reported as UNHEALTHY.

At first, the infrastructure configuration appeared correct:

- MIG existed
- Backend service existed
- Health check existed
- Firewall allowed HTTP
- Web instances had the correct network tags
- Instances had private IP addresses
- Cloud NAT was configured

However, the health check continued to fail.

---

## Investigation

The VM serial console logs revealed:

```text
Failed to fetch packages.cloud.google.com
Cannot initiate the connection
Network is unreachable
```

The web instances were unable to access the public internet during startup process.

The startup script requires internet access to install Nginx:

```bash
apt-get update
apt-get install -y nginx
```

Without Nginx running on port 80, the load balancer health check could not succeed.

---

## Root Cause

The Managed Instance Group (MIG) instances were created **before the web subnet was added to Cloud NAT**.

Therefore:

```text
Private VM
   │
   ├── No external IP
   │
   └── No NAT route at creation time
             │
             ▼
        apt-get failed
             │
             ▼
        Nginx not installed
             │
             ▼
        Port 80 unavailable
             │
             ▼
       Health check failed
             │
             ▼
      no healthy upstream
```

An important lessons learned was that **adding Cloud NAT later does not automatically rerun a VM's startup script**.

---

## Resolution

The web subnet was added to Cloud NAT.

The existing MIG instances are replaced so that the new instances would execute the configured startup script with working outbound connection.

```bash
gcloud compute instance-groups managed rolling-action replace \
  web-instance-group \
  --zone=us-central1-a \
  --max-unavailable=2
```

The replacement instances successfully:

1. Booted
2. Obtained private IP addresses
3. Reached the internet through Cloud NAT
4. Installed Nginx
5. Started the web server
6. Passed the HTTP health check
7. Became healthy load-balancer backends

The load balancer subsequently returned:

```html
<h1>GCP Web Server: web-cd2g</h1>
```

This validated the complete traffic path.

---

# Lessons Learned

This troubleshooting activity demonstrated some important cloud operations concepts:

### 1. Private instances still require outbound connectivity

A VM without a public IP can still access the internet by using Cloud NAT.

### 2. Startup scripts depend on network availability

Installing packages during VM initialization obiously requires outbound connectivity.

### 3. Infrastructure changes do not always affect existing VMs

Adding Cloud NAT does not cause an existing VM's startup script to execute it again.

### 4. Health checks are useful diagnostic tools

An unhealthy backend can be caused by several layers:

```text
Load Balancer
      ↓
Backend Service
      ↓
Health Check
      ↓
Firewall
      ↓
Network
      ↓
VM
      ↓
Application
```

Troubleshooting issues should therefore proceed systematically through each layer.

### 5. Logs are critical

Serial console output certainly helped identify the actual issues instead of simply treating the load balancer's `no healthy upstream` message as the root cause.

---

# Security Controls

The project implements several security controls:

| Control                   | Implementation                            |
| ------------------------- | ----------------------------------------- |
| Network segmentation      | Separate Web, App, and Management subnets |
| Public exposure reduction | Private MIG instances                     |
| Administrative access     | IAP-based SSH                             |
| Network filtering         | VPC firewall rules                        |
| Outbound access           | Cloud NAT                                 |
| Network visibility        | VPC Flow Logs                             |
| Workload identity         | Dedicated service account                 |
| Permissions               | Logging Writer role                       |
| Availability              | Managed Instance Group                    |
| Traffic protection        | Load-balancer health checks               |
| Monitoring                | Cloud Monitoring dashboard                |

---

# Repository Structure

```text
gcp-secure-network-lab/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── terraform/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── network.tf
│   ├── firewall.tf
│   ├── nat.tf
│   ├── compute.tf
│   ├── load-balancer.tf
│   ├── iam.tf
│   └── monitoring.tf
│
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   ├── troubleshooting.md
│   └── security.md
│
├── diagrams/
│   └── architecture.png
│
├── screenshots/
│   ├── 01-vpc.png
│   ├── 02-subnets.png
│   ├── 03-firewall.png
│   ├── 04-mig.png
│   ├── 05-load-balancer.png
│   ├── 06-backend-health.png
│   ├── 07-flow-logs.png
│   └── 08-monitoring-dashboard.png
│
└── .github/
    └── workflows/
        └── terraform.yml
```

---

# Project Highlights

### Cloud Networking

- Custom VPC
- Multiple subnet architecture
- Private IP addressing
- Cloud Router
- Cloud NAT
- VPC Flow Logs

### Cloud Security

- IAP SSH
- Restricted firewall rules
- Private VM architecture
- Dedicated service account
- IAM least-privilege approach

### High Availability

- Managed Instance Group
- Multiple web instances
- HTTP health checks
- Global external load balancer

### Automation

- Terraform Infrastructure as Code
- VM startup scripts
- Automated instance replacement
- Repeatable infrastructure deployment

### Monitoring

- VM CPU monitoring
- Network traffic monitoring
- Load-balancer request monitoring
- Backend request monitoring

### Troubleshooting

- Diagnosed unhealthy load-balancer backends
- Used serial console logs
- Identified missing outbound connectivity
- Connected Cloud NAT configuration to startup-script failure
- Replaced MIG instances to recover the deployment

---

# Future Improvements

Potential extensions to this project include:

- HTTPS with a managed SSL certificate
- Cloud Armor for web application protection
- Cloud Logging alerting
- Uptime checks
- Autoscaling policies for the MIG
- Regional multi-zone deployment
- Cloud SQL private connectivity
- Private Service Connect
- Bastion-free administration using IAP
- Secret Manager integration
- Terraform remote state
- Terraform CI/CD with GitHub Actions
- Security Command Center integration
- Centralized logging and security alerting
- Additional monitoring and alert policies

---

# Skills Demonstrated

```text
Google Cloud
├── VPC Networking
├── Compute Engine
├── Managed Instance Groups
├── Load Balancing
├── Cloud NAT
├── Cloud Router
├── IAM
├── IAP
├── Cloud Monitoring
└── VPC Flow Logs

Infrastructure as Code
└── Terraform

Networking
├── IPv4 Subnetting
├── Routing
├── NAT
├── Firewalling
├── HTTP
└── Load Balancing

Security
├── Network Segmentation
├── Least Privilege
├── Private Infrastructure
├── Secure Administration
└── Network Monitoring

Operations
├── Troubleshooting
├── Logging
├── Monitoring
├── Health Checks
└── Incident Analysis
```

---

# Author

**Edison Encinas**

An Educator with a background in networking, cybersecurity, automation, and data analytics.

Areas of interest:

- Cloud Engineering
- Cloud Networking
- Cloud Security
- Infrastructure as Code
- Network Automation
- DevOps
- Security Operations

---

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE) for details.

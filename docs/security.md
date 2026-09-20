# Security

The GCP Secure Network Lab uses multiple security controls to reduce unnecessary exposure and control access to cloud resources.

## Security Controls

| Control              | Implementation                                           |
| -------------------- | -------------------------------------------------------- |
| Network Segmentation | Separate Web, App, and Management subnets                |
| Private VMs          | Web MIG and App Server use private IPs                   |
| Firewall             | Restricted ingress using source ranges and network tags  |
| Secure SSH           | IAP TCP forwarding instead of public SSH                 |
| Outbound Access      | Cloud NAT instead of public VM IPs                       |
| Network Visibility   | VPC Flow Logs on Web and App subnets                     |
| IAM                  | Dedicated service account with `roles/logging.logWriter` |
| Health Checks        | Load balancer only sends traffic to healthy backends     |
| Monitoring           | Cloud Monitoring dashboard for infrastructure visibility |

## Firewall Rules

### HTTP

```text
allow-http
TCP/80
Source: 0.0.0.0/0
Target: web-server
```

Allows HTTP traffic to the web tier.

### Internal

```text
allow-internal
TCP / UDP / ICMP
Source: 10.10.0.0/16
```

Allows internal communication within the lab network.

### IAP SSH

```text
allow-iap-ssh
TCP/22
Source: 35.235.240.0/20
Target: iap-ssh
```

Allows SSH through Google Identity-Aware Proxy without exposing SSH directly to the internet.

## Private VM Design

The web MIG instances and application server do not have public IP addresses.

```text
Internet
   │
   ▼
Load Balancer
   │
   ▼
Private Web VMs
```

For outbound connections:

```text
Private VM
   │
   ▼
Cloud NAT
   │
   ▼
Internet
```

This separates public access from backend infrastructure.

## IAM

The web instances use a dedicated service account:

```text
web-server-sa
```

It is granted:

```text
roles/logging.logWriter
```

This avoids using unnecessary broad permissions for the web workload.

## Network Monitoring

VPC Flow Logs are enabled on the Web and App subnets:

```text
Aggregation: 5 seconds
Sampling: 50%
Metadata: INCLUDE_ALL_METADATA
```

These logs provide network visibility for troubleshooting and security analysis.

## Security Considerations

This is a learning/portfolio environment rather than a production system. Future security improvements could include:

- HTTPS
- Cloud Armor
- More restrictive firewall rules
- Multi-zone deployment
- Secret Manager
- Security Command Center
- Centralized alerting

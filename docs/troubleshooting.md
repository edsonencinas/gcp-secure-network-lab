# Troubleshooting

## Load Balancer: `no healthy upstream`

### Problem

The Global External HTTP Load Balancer initially returned:

```text
no healthy upstream
```

The Managed Instance Group (MIG) instances were reported as unhealthy.

### Investigation

The following components were checked:

- Load balancer configuration
- Backend service
- Health check
- MIG instances
- Firewall rules
- Network tags
- Cloud NAT
- VM startup script

The VM serial console showed:

```text
Failed to fetch packages.cloud.google.com
Network is unreachable
```

The startup script was unable to install Nginx:

```bash
apt-get update
apt-get install -y nginx
```

### Root Cause

The MIG instances were created **before the Web subnet was configured for Cloud NAT**.

Because the web VMs had:

- Private IP addresses
- No public IP addresses
- No working NAT connectivity

the startup script could not download and install Nginx.

```text
Private VM
    ↓
No NAT connectivity
    ↓
apt-get failed
    ↓
Nginx not installed
    ↓
Port 80 unavailable
    ↓
Health check failed
    ↓
no healthy upstream
```

### Resolution

The Web subnet was added to Cloud NAT.

Existing MIG instances were then replaced so the startup script would run again:

```bash
gcloud compute instance-groups managed rolling-action replace \
  web-instance-group \
  --zone=us-central1-a \
  --max-unavailable=2
```

The replacement instances successfully installed Nginx and passed the HTTP health check.

### Validation

The load balancer then returned:

```html
<h1>GCP Web Server: web-cd2g</h1>
```

This confirmed that:

- Load balancer forwarding worked
- Backend service was functioning
- MIG instances were healthy
- Nginx was running
- Private VMs had outbound connectivity through Cloud NAT

## Key Lesson

Adding Cloud NAT does **not** automatically rerun a VM's startup script. When a startup script depends on outbound connectivity, existing instances may need to be recreated or otherwise reinitialized after fixing the network configuration.

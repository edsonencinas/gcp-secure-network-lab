# Deployment

This project uses **Terraform** to deploy the core Google Cloud infrastructure.

## Prerequisites

- Google Cloud project
- Google Cloud CLI (`gcloud`)
- Terraform
- Authenticated GCP account
- Required GCP APIs and permissions

## 1. Authenticate

```bash
gcloud auth login
```

Set the project:

```bash
gcloud config set project gcp-secure-network-lab
```

Verify:

```bash
gcloud config get-value project
```

## 2. Initialize Terraform

Navigate to the Terraform directory:

```bash
cd terraform
```

Initialize the working directory:

```bash
terraform init
```

## 3. Validate Configuration

Format the Terraform files:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

## 4. Review the Plan

```bash
terraform plan
```

Review the resources Terraform will create or modify.

## 5. Deploy

```bash
terraform apply
```

Enter `yes` when prompted.

Terraform creates the VPC, subnets, firewall rules, Cloud NAT, compute resources, Managed Instance Group, load balancer, IAM resources, and related infrastructure.

## 6. Verify Deployment

Check the VPC:

```bash
gcloud compute networks list
```

Check the MIG:

```bash
gcloud compute instance-groups managed list
```

Check the load balancer:

```bash
gcloud compute forwarding-rules list
```

Get the load-balancer IP:

```bash
gcloud compute addresses list
```

Test the web service:

```bash
curl http://<LOAD_BALANCER_IP>
```

Expected response:

```html
<h1>GCP Web Server: <hostname></h1>
```

## 7. Test Private VM Access

Connect to the private application server using IAP:

```bash
gcloud compute ssh app-server \
  --zone=us-central1-a \
  --tunnel-through-iap
```

Test outbound connectivity:

```bash
curl https://www.google.com
```

This verifies that the private VM can access the internet through Cloud NAT.

## 8. Monitoring

The Cloud Monitoring dashboard is currently configured manually in Google Cloud.

It provides visibility into:

- Web MIG CPU utilization
- App Server CPU utilization
- Network traffic
- Load-balancer requests
- Backend requests

## Destroy the Environment

When the lab is no longer needed:

```bash
terraform destroy
```

> **Warning:** `terraform destroy` removes the infrastructure managed by Terraform. Use it only when you are finished with the lab.

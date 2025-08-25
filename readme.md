# Abhishek EKS Terraform Deployment

This project automates the deployment of an **AWS EKS Cluster** with a **Jump Box** using Terraform, fully configured with Docker, kubectl, Helm, and a local user `Abhishek` for direct access.

---

## Architecture Overview

* **VPC:** 10.0.0.0/16
* **Subnets:** 2 Public Subnets across Availability Zones
* **Internet Gateway & Route Table** for public access
* **EKS Cluster:** Version 1.30
* **Node Group:** Managed, configurable instance type, desired/min/max nodes
* **Jump Box EC2:** t3.medium with Docker, kubectl, Helm, and local user `Abhishek`
* **Security Groups:** Allow SSH access to Jump Box

---

## Terraform Files

* `providers.tf`: AWS provider configuration
* `variables.tf`: All input variables with defaults
* `main.tf`: Resources for VPC, subnets, EKS cluster, node group, Jump Box
* `outputs.tf`: Outputs for cluster endpoint, certificate, and Jump Box IP

---

## Prerequisites

* Terraform >= 1.5
* AWS CLI configured with appropriate IAM permissions
* SSH Key (name provided in `variables.tf` as `abhishek-key`)
* AWS account with sufficient quota for EKS and EC2

---

## How to Deploy

1. Clone the repository:

```bash
git clone <repo-url>
cd <repo-directory>
```

2. Initialize Terraform:

```bash
terraform init
```

3. Review plan:

```bash
terraform plan
```

4. Apply deployment:

```bash
terraform apply
```

Terraform will create all resources. Confirm with `yes` when prompted.

---

## Accessing the Jump Box

After deployment, retrieve the public IP from Terraform outputs:

```bash
terraform output jump_box_public_ip
```

SSH into the Jump Box:

```bash
ssh -i abhishek-key.pem ec2-user@<jump_box_public_ip>
```

Switch to local user `Abhishek`:

```bash
sudo su - Abhishek
```

---

## Verify Tools

Check installed tools:

```bash
kubectl get nodes
helm version
docker ps
```

The kubeconfig is already configured for both `ec2-user` and `Abhishek`.

---

## Variables

* `aws_region`: AWS region (default `us-east-1`)
* `ssh_key_name`: SSH key for EC2 Jump Box
* `node_instance_type`: EKS worker node type (default `t3.medium`)
* `node_desired_capacity`: Desired nodes (default 2)
* `node_min_capacity`: Minimum nodes (default 1)
* `node_max_capacity`: Maximum nodes (default 3)

---

## Outputs

* `cluster_endpoint`: EKS API endpoint
* `cluster_certificate_authority_data`: Base64 encoded CA
* `jump_box_public_ip`: Public IP of Jump Box

---

## Notes

* The user `Abhishek` is created with password `Abhishek` and sudo access.
* Docker, kubectl, and Helm are installed automatically on the Jump Box.
* Kubeconfig is auto-configured for both `ec2-user` and `Abhishek`.
* Adjust Terraform variables if needed for region, SSH key, or node sizing.

---

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Confirm with `yes` when prompted.

---

## Support

For any issues, check AWS IAM permissions, VPC limits, and EKS quotas.

# MediaWiki on AWS EKS with Terraform

This project deploys a production-ready **MediaWiki** setup on **AWS EKS** using **Terraform** and **Helm**, including a jump box for secure access.

---

## Features

* VPC with **two public subnets** (`us-east-1a` / `us-east-1b`)
* **EKS v1.28** cluster with managed node group
* IAM role grants `system:masters` to your current identity (kubectl works immediately)
* Kubernetes and Helm providers configured (IAM exec auth)
* Installs local Helm charts:

  * `./mediawiki-mariadb-chart`
  * `./mediawiki-chart`
* Optional **jump box** for secure cluster access

---

## Project Structure

```
.
├─ main.tf
├─ providers.tf
├─ versions.tf
├─ variables.tf
├─ values-mediawiki-mariadb.yaml
├─ values-mediawiki.yaml
├─ outputs.tf
├─ mediawiki-mariadb-chart/   (your Helm chart)
└─ mediawiki-chart/           (your Helm chart)
```

---

## Prerequisites

* Terraform v1.5+
* AWS CLI configured
* SSH key pair in AWS (`ssh_key_name`)
* Local Helm charts for MediaWiki and MariaDB

---

## Deploying

1. Initialize Terraform:

```bash
terraform init
```

2. Apply the configuration:

```bash
terraform apply -auto-approve
```

3. (Optional) Save kubeconfig locally:

```bash
aws eks update-kubeconfig --region us-east-1 --name mediawiki-eks
kubectl get nodes
kubectl get svc -n mediawiki
```

---

## Accessing MediaWiki

### 1️⃣ Get External IP

```bash
kubectl get svc -n mediawiki
```

* `mediawiki` service type should be `LoadBalancer`
* Open a browser at: `http://<EXTERNAL-IP>`

If `EXTERNAL-IP` is `<pending>`, wait a few minutes.

---

### 2️⃣ Persist `LocalSettings.php`

**Option A: ConfigMap (simple)**

```bash
kubectl -n mediawiki create configmap localsettings --from-file=LocalSettings.php
```

Patch Deployment to mount the ConfigMap:

```yaml
volumeMounts:
  - name: localsettings
    mountPath: /var/www/html/LocalSettings.php
    subPath: LocalSettings.php
volumes:
  - name: localsettings
    configMap:
      name: localsettings
      items:
        - key: LocalSettings.php
          path: LocalSettings.php
```

Re-deploy the chart:

```bash
helm upgrade mediawiki ./mediawiki-chart -n mediawiki -f values-mediawiki.yaml
```

**Option B: PVC/EFS (advanced)**

* Use a PersistentVolume so the file survives upgrades.

---

## Jump Box Deployment

### 1️⃣ Connect to Jump Box

```bash
ssh -i ~/.ssh/<your-key>.pem ec2-user@<jump_box_public_ip>
```

### 2️⃣ Install kubectl and AWS CLI

```bash
sudo yum install -y awscli
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 3️⃣ Configure kubeconfig

```bash
aws eks --region <your-region> update-kubeconfig --name <cluster_name>
kubectl get nodes
```

---

## Accessing MediaWiki via Jump Box

**Option A: LoadBalancer**

* Use EXTERNAL-IP in browser: `http://<EXTERNAL-IP>`

**Option B: ClusterIP (internal)**

1. Port-forward:

```bash
kubectl port-forward svc/mediawiki 8080:80 -n mediawiki
```

2. SSH tunnel from local machine:

```bash
ssh -i ~/.ssh/<your-key>.pem -L 8080:localhost:8080 ec2-user@<jump_box_public_ip>
```

* Open browser at `http://localhost:8080`

---

## Database Access (Optional)

MariaDB is `ClusterIP`:

```bash
kubectl port-forward svc/database 3306:3306 -n mediawiki
```

* Connect locally using `127.0.0.1:3306`

---

## Outputs

* Jump box public IP
* EKS cluster info (nodes, services)

---

## Cleanup

To destroy all resources:

```bash
terraform destroy -auto-approve
```

---

## Notes

* Make sure your Helm charts are configured correctly before deployment.
* LoadBalancer provisioning may take a few minutes.
* Consider using PersistentVolumes for MediaWiki data in production.
* This setup is minimal for testing; adjust node size and subnets for production.

---

**Enjoy your MediaWiki on EKS!**

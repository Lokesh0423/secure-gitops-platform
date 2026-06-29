# Secure GitOps Platform

![CI](https://github.com/Lokesh0423/secure-gitops-platform/actions/workflows/ci-cd.yaml/badge.svg)

A production-grade Internal Developer Platform built on Azure Kubernetes Service, demonstrating Platform Engineering, DevSecOps, and GitOps principles end-to-end.

---

## Architecture Overview

```
Developer pushes code
        │
        ▼
┌─────────────────────┐
│   GitHub Actions    │  <- CI: Build + Test + Trivy Scan
└────────┬────────────┘
         │ image pushed to ACR (only if scan passes)
         ▼
┌─────────────────────┐
│      ArgoCD         │  <- GitOps: auto-syncs Helm chart to AKS
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   AKS Cluster       │  <- Provisioned by Terraform
│  ┌───────────────┐  │
│  │ OPA Gatekeeper│  │  <- Policy enforcement (no root, resource limits required)
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │  App (Helm)   │  │  <- Packaged via Helm chart
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │  Prometheus   │  │  <- Metrics scraping
│  │  + Grafana    │  │  <- Dashboards + alerting
│  └───────────────┘  │
└─────────────────────┘
```

---

## Stack

| Layer              | Tool                   |
| ------------------ | ---------------------- |
| Cloud Infra        | Azure (AKS, ACR, VNet) |
| IaC                | Terraform              |
| App Packaging      | Helm                   |
| GitOps             | ArgoCD                 |
| CI/CD              | GitHub Actions         |
| Container Security | Trivy                  |
| Policy Enforcement | OPA Gatekeeper         |
| Monitoring         | Prometheus + Grafana   |
| Language           | Node.js (Express)      |

---

## Project Structure

```
secure-gitops-platform/
├── infrastructure/        # Terraform: AKS + networking
├── app/                   # Node.js app source
├── helm/                  # Helm chart for app deployment
├── argocd/                # ArgoCD Application manifests
├── security/              # Trivy config + OPA policies
├── monitoring/            # Prometheus + Grafana configs
└── .github/workflows/     # CI/CD pipeline
```

---

## Key Design Decisions

**Why ArgoCD over manual kubectl apply?**
GitOps means the Git repo is the single source of truth. ArgoCD continuously reconciles cluster state against the repo, so any drift is automatically corrected. This eliminates deploy inconsistencies across environments.

**Why OPA Gatekeeper?**
Kubernetes RBAC controls who can do what, but does not enforce what they deploy. OPA policies block non-compliant workloads at admission time. Containers running as root are rejected before they ever reach a node.

**Why Trivy in CI, not just at runtime?**
Shift-left security. Catching a critical CVE at image build time costs minutes to fix. Catching it in production costs hours of incident response and potential data exposure.

**Why a monorepo?**
In a real platform team, keeping infra, app, and deployment config in separate repos creates coordination overhead. A monorepo makes the full delivery lifecycle visible and auditable in one place.

---

## Getting Started

### Prerequisites

- Azure CLI + active subscription
- Terraform >= 1.5
- kubectl
- Helm >= 3.x
- ArgoCD CLI

### 1. Provision Infrastructure

```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl

```bash
az aks get-credentials --resource-group rg-gitops-dev --name aks-gitops-dev
```

### 3. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 4. Deploy App via ArgoCD

```bash
kubectl apply -f argocd/application.yaml
```

### 5. Access Grafana Dashboard

```bash
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Open http://localhost:3000
```

---

## CI/CD Pipeline Flow

```
push to main
    │
    ├─ lint & test
    ├─ docker build
    ├─ trivy image scan ──► FAIL = pipeline stops, no deploy
    ├─ push to ACR
    └─ update Helm values (new image tag)
            │
            └─ ArgoCD detects git change -> syncs to AKS
```

---

## Security Controls

| Control                      | Implementation                       |
| ---------------------------- | ------------------------------------ |
| Image vulnerability scanning | Trivy (CRITICAL CVEs block pipeline) |
| No root containers           | OPA ConstraintTemplate               |
| Resource limits required     | OPA ConstraintTemplate               |
| Least privilege RBAC         | Kubernetes ServiceAccount per app    |
| Secrets management           | Azure Key Vault + CSI driver         |

---

## Monitoring

- Prometheus scrapes app metrics every 15s
- Grafana dashboards: request rate, error rate, pod CPU/memory
- Alertmanager fires on error rate above 5% for 5 minutes

---

## Challenges and Solutions

**CI pipeline cache failures in GitHub Actions**
The npm cache-dependency-path was mismatched with the working-directory context, causing the cache step to fail on every run. Identified the path conflict and removed the cache config to unblock the pipeline.

**Terraform module variable contracts**
The networking module was missing its variables.tf file, causing unsupported argument errors during terraform validate. Defined the full module interface and fixed terraform fmt compliance across all modules.

**Local dev environment disk pressure**
C: drive reached 100% capacity, blocking npm installs and git operations entirely. Disabled hibernation to free 16GB, redirected npm cache to D: drive, and cleared system temp files to restore a working dev environment.

---

## Related Repos

- [terraform-azure-infra](https://github.com/Lokesh0423/terraform-azure-infra)
- [azure-cicd-pipeline](https://github.com/Lokesh0423/azure-cicd-pipeline)
- [k8s-helm-charts](https://github.com/Lokesh0423/k8s-helm-charts)
- [nodejs-k8s-minikube-app](https://github.com/Lokesh0423/nodejs-k8s-minikube-app)

---

## Author

**Lokesh Kumar Gaddala** - Cloud DevOps Engineer

[LinkedIn](https://linkedin.com/in/lokeshkumargaddala) · [GitHub](https://github.com/Lokesh0423)

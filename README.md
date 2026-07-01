# secure-gitops-platform

Production-grade GitOps platform combining Platform Engineering, DevSecOps, and GitOps best practices.

**Stack**: Kubernetes (AKS), ArgoCD, Helm, Terraform, GitHub Actions, Trivy, OPA Gatekeeper, Prometheus, Grafana

## Architecture

Git Push (main)
│
▼
GitHub Actions CI Pipeline
├─ Lint & Test (Jest, ESLint)
├─ Build & Security Scan (Trivy)
├─ SARIF report upload
└─ Push image to registry (conditional)
│
▼
ArgoCD Controller (watches Helm values)
│
├─ Pull image from registry
├─ Apply Helm chart
└─ Deploy to AKS (staging → production)
│
▼
OPA Gatekeeper (policy enforcement)
└─ Validate workload security constraints
Prometheus + Grafana (observability)
└─ Scrape application metrics at /metrics endpoint

## Repository Structure
secure-gitops-platform/
├── .github/workflows/
│   └── ci-cd.yaml              # Multi-job GitHub Actions pipeline
├── app/
│   ├── src/index.js            # Express Node.js app with health & metrics endpoints
│   ├── Dockerfile              # Multi-stage build, non-root user, npm --omit=dev
│   ├── tests/                  # Jest tests with 100% coverage
│   └── package.json
├── helm/charts/app/
│   ├── values.yaml             # Parameterized deployment config
│   ├── templates/              # K8s manifests (deployment, service, configmap)
│   └── Chart.yaml
├── argocd/
│   └── application.yaml        # ArgoCD Application resource for auto-sync
├── infrastructure/terraform/
│   ├── environments/dev/       # Dev environment Terraform
│   ├── modules/                # Reusable modules (AKS, networking, ACR)
│   └── README.md               # Infrastructure setup guide
├── monitoring/prometheus/
│   ├── prometheus.yaml         # Scrape config, retention policy
│   └── alerts.yaml             # AlertManager rules (optional)
├── security/
│   └── opa-gatekeeper/         # OPA policies (enforce pod security, resource limits)
└── README.md

## Key Features

- **Shift-Left Security**: Trivy vulnerability scanning fails the pipeline on CRITICAL/HIGH CVEs
- **GitOps Automation**: ArgoCD syncs from Git to AKS automatically
- **Infrastructure as Code**: Terraform provisions AKS, networking, ACR end-to-end
- **Policy as Code**: OPA Gatekeeper enforces security and resource constraints
- **Observability**: Prometheus metrics, health checks, readiness probes, structured logging
- **Zero-Downtime Deployments**: Rolling updates with maxUnavailable: 0
- **Production-Ready**: Non-root containers, resource limits, RBAC, network policies

## Pipeline Features

- **CI**: Lint (ESLint), Test (Jest, 100% coverage), security scan (Trivy)
- **CD**: Conditional Docker push and Helm value updates only when scan passes
- **Artifact Upload**: Test coverage reports, Trivy SARIF for GitHub Security dashboard
- **Branch Strategy**: main branch triggers full production deployment

## Setup

### Prerequisites
- Kubernetes cluster (AKS, EKS, or local Minikube)
- ArgoCD installed (argocd CLI + namespace)
- Terraform installed (v1.5.0+)
- kubectl configured to access your cluster

### Quick Start

1. Clone the repo:
   git clone https://github.com/Lokesh0423/secure-gitops-platform.git
   cd secure-gitops-platform

2. Deploy infrastructure (optional, for AKS):
   cd infrastructure/terraform/environments/dev
   terraform init && terraform plan && terraform apply

3. Install ArgoCD:
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

4. Create ArgoCD Application (watches this repo):
   kubectl apply -f argocd/application.yaml

5. Deploy Prometheus (observability):
   kubectl apply -f monitoring/prometheus/prometheus.yaml

6. Push to main to trigger the full pipeline:
   git push origin main

## Local Development

### Run Tests Locally
cd app
npm install
npm test

### Build Docker Image
docker build -t secure-gitops-app:latest ./app
docker run -p 3000:3000 secure-gitops-app:latest

### Run Trivy Scan Locally
trivy image --severity CRITICAL,HIGH secure-gitops-app:latest

### Apply Helm Chart Locally (Minikube)
helm install app helm/charts/app --namespace default
kubectl port-forward svc/app 3000:3000

## Application Endpoints

- GET / — Service info (name, version, status, timestamp)
- GET /health — Liveness probe (returns status: healthy)
- GET /ready — Readiness probe (returns status: ready)
- GET /metrics — Prometheus metrics (scrape target for monitoring)

## Security Practices

✓ Non-root container user (UID 1001)
✓ Multi-stage Docker build (minimal final image size)
✓ No devDependencies in production (npm ci --omit=dev)
✓ Resource limits enforced via Helm values
✓ OPA Gatekeeper policies for pod security
✓ Trivy scanning in CI (shift-left security)
✓ SARIF reports for GitHub Security dashboard

## Related Repositories

- terraform-azure-infra: AKS, networking, ACR modules
- azure-cicd-pipeline: Azure DevOps multi-stage pipeline
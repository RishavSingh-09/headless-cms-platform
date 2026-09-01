# Architecture

## Overview

A multi-environment (dev / uat / prod) headless CMS on AWS. Content authors use Strapi (Node.js) to manage articles; a Next.js React frontend serves them to users. All workloads run as Docker containers on Amazon EKS with EC2 managed node groups. Postgres is on RDS; media assets live in S3; CloudFront caches globally.

## Environments

| Env  | VPC CIDR      | Nodes                 | RDS class     | Multi-AZ |
|------|---------------|-----------------------|---------------|----------|
| dev  | 10.10.0.0/16  | 1-3 × t3.medium       | db.t3.micro   | no       |
| uat  | 10.20.0.0/16  | 2-4 × t3.large        | db.t3.small   | no       |
| prod | 10.30.0.0/16  | 3-8 × t3.large/m5.large | db.m5.large | yes      |

Each environment is a separate Terraform stack under `infrastructure/terraform/environments/<env>/` with its own tfvars, guaranteeing no config drift.

## Request Flow

1. User → CloudFront (edge cache, TLS via ACM)
2. → ALB → NGINX Ingress Controller (routes `/api/*` to backend, `/*` to frontend)
3. Frontend Pod (Next.js SSR) fetches `/api/articles` from backend Service
4. Backend Pod (Strapi/Node) queries RDS Postgres and streams media to/from S3
5. Prometheus scrapes `/metrics` on each pod; CloudWatch collects AWS-level metrics

## Security

- **IAM**: least-privilege policy for backend to access only the media S3 bucket; separate cluster and node roles.
- **Network**: pods in private subnets; RDS SG allows :5432 only from VPC CIDR; NetworkPolicies enforce `frontend → backend` and `ingress-nginx → frontend` only.
- **Secrets**: DB password via Kubernetes Secret (external secrets/Secrets Manager in real prod).
- **TLS**: ACM cert terminated at ALB/CloudFront; Ingress redirects HTTP→HTTPS.
- **RBAC**: `cms-app-sa` ServiceAccount with read-only Role inside `cms` ns; `cms-developer` ClusterRole for humans.

## Delivery

- **Terraform** modules for VPC/EKS/RDS/IAM, one stack per env.
- **Helm** chart with overlays under `environments/{dev,uat,prod}.yaml`; single-command rollback via `helm rollback cms <rev>`.
- **Jenkins** and **GitHub Actions** run identical stages: test → build → Trivy → push → gated deploy.

## Observability

- **Prometheus** scrapes pod annotations (`prometheus.io/scrape: "true"`) and kube-state-metrics.
- **Grafana** dashboard `cms-overview` shows request rate, 5xx rate, CPU/memory per pod.
- **Alertmanager** rules: PodCrashLooping, HighErrorRate, HighCPU, HighMemory, BackendDown.
- **CloudWatch** for RDS, ALB, EKS control-plane, and cost metrics.

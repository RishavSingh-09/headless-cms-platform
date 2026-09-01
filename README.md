# Multi-Environment Headless CMS Platform on AWS

Production-style headless CMS platform (**Strapi + Next.js**) deployable to **Amazon EKS** with EC2 managed node groups, **RDS PostgreSQL**, and **S3** media storage. React frontend and Node.js backend run as Docker containers, provisioned via **Terraform**, released with **Helm**, and shipped through **Jenkins** and **GitHub Actions**. Observability via **Prometheus + Grafana** and **CloudWatch**.

> Demo endpoints below use placeholder EC2 / ALB DNS values — replace with real outputs after `terraform apply`.

## Demo Endpoints (placeholders)

| Service            | URL / Host                                        |
|--------------------|---------------------------------------------------|
| Frontend (Next.js) | `http://ec2-13-232-100-10.ap-south-1.compute.amazonaws.com` |
| Backend (Strapi)   | `http://ec2-13-232-100-10.ap-south-1.compute.amazonaws.com:1337` |
| Grafana            | `http://ec2-13-232-100-10.ap-south-1.compute.amazonaws.com:3000` |
| Prometheus         | `http://ec2-13-232-100-10.ap-south-1.compute.amazonaws.com:9090` |

## Architecture

```
        ┌──────────────┐        ┌─────────────────┐
Users ──▶  CloudFront  ├────────▶ ALB / NGINX Ing │
        └──────────────┘        └────────┬────────┘
                                         │
                     ┌───────────────────┴──────────────────┐
                     │            Amazon EKS                │
                     │  ┌──────────┐        ┌────────────┐  │
                     │  │ Next.js  │◀──────▶│  Strapi    │  │
                     │  │ (React)  │        │  (Node.js) │  │
                     │  └──────────┘        └─────┬──────┘  │
                     │                            │         │
                     │  Prometheus + Grafana      │         │
                     └────────────────────────────┼─────────┘
                                                  │
                                ┌─────────────────┼──────────────┐
                                ▼                 ▼              ▼
                         RDS PostgreSQL         S3           CloudWatch
```

## Repo Layout

```
apps/                  Strapi backend + Next.js frontend
docker/                Dockerfiles for each service
infrastructure/
  terraform/           Reusable modules (vpc, eks, rds, iam) + dev/uat/prod
  helm/                Helm chart + per-env values
  k8s/                 Raw manifests (Ingress, RBAC, HPA, NetworkPolicy)
ci/
  jenkins/             Declarative Jenkinsfile
  github-actions/      Reusable workflow snippets
.github/workflows/     Live GitHub Actions workflow
monitoring/            Prometheus rules + Grafana dashboards
scripts/               Python + Bash automation
docs/                  Architecture & runbooks
```

## Quickstart (local)

```bash
docker compose -f docker/docker-compose.yml up --build
```

## Provision AWS (per environment)

```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform apply -var-file=dev.tfvars
```

## Deploy to EKS

```bash
aws eks update-kubeconfig --name cms-dev --region ap-south-1
helm upgrade --install cms infrastructure/helm/cms-platform \
  -f infrastructure/helm/cms-platform/environments/dev.yaml
```

## CI/CD

- **Jenkins**: `ci/jenkins/Jenkinsfile` — build → test → Trivy → deploy (gated)
- **GitHub Actions**: `.github/workflows/ci-cd.yml` — same stages, PR-first

## Container Images

Published to Docker Hub as:

- `rishavsingh09/cms-backend:<tag>`
- `rishavsingh09/cms-frontend:<tag>`

## Author

**Rishav Singh** — [github.com/RishavSingh-09](https://github.com/RishavSingh-09)

# Runbook

## Push a new release

```bash
git tag v1.2.3 && git push origin v1.2.3
# GitHub Actions builds, scans, pushes to Docker Hub, and deploys to dev.
# Trigger uat/prod manually via workflow_dispatch (requires environment reviewer).
```

## Rollback

```bash
helm history cms -n cms
helm rollback cms <REVISION> -n cms
```

## Take an on-demand RDS snapshot

```bash
python scripts/rds_backup.py --env prod --retention-days 30
```

## Nightly cost cleanup (unattached EBS, unassociated EIPs, old snapshots)

```bash
python scripts/cost_cleanup.py --env dev --dry-run
python scripts/cost_cleanup.py --env dev
```

## Tear down an environment

```bash
./scripts/teardown_env.sh dev
```

## Common kubectl checks

```bash
kubectl -n cms get pods -o wide
kubectl -n cms logs deploy/cms-backend --tail=200 -f
kubectl -n cms describe hpa
kubectl -n cms get networkpolicy
```

## Local dev

```bash
docker compose -f docker/docker-compose.yml up --build
# Frontend: http://localhost:3000
# Backend:  http://localhost:1337/api/articles
```

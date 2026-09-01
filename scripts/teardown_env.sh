#!/usr/bin/env bash
# teardown_env.sh — Tear down an entire environment (Helm release + Terraform).
#
# Usage: ./teardown_env.sh dev
#
# Order:
#   1. helm uninstall (drops k8s workloads)
#   2. terraform destroy (drops AWS infra)
set -euo pipefail

ENV=${1:?"usage: $0 <dev|uat|prod>"}
REGION=${AWS_REGION:-ap-south-1}
CLUSTER="cms-${ENV}"

if [[ "$ENV" == "prod" ]]; then
  read -r -p "You are about to DESTROY PROD. Type 'destroy-prod' to continue: " confirm
  [[ "$confirm" == "destroy-prod" ]] || { echo "aborted"; exit 1; }
fi

echo "[1/2] Uninstalling Helm release from $CLUSTER"
if aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION" 2>/dev/null; then
  helm uninstall cms -n cms || true
  kubectl delete ns cms --ignore-not-found
else
  echo "  cluster $CLUSTER not reachable, skipping helm step"
fi

echo "[2/2] terraform destroy for $ENV"
TF_DIR="infrastructure/terraform/environments/${ENV}"
pushd "$TF_DIR" >/dev/null
terraform init -input=false
terraform destroy -auto-approve -var-file="${ENV}.tfvars"
popd >/dev/null

echo "[+] Environment ${ENV} torn down."

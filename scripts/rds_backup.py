#!/usr/bin/env python3
"""
rds_backup.py — Take on-demand snapshots of RDS instances by tag and prune old ones.

Usage:
  python rds_backup.py --env dev --retention-days 7 --region ap-south-1
"""
import argparse
import datetime as dt
import sys

import boto3
from botocore.exceptions import ClientError


def snapshot_id(instance_id: str) -> str:
    ts = dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    return f"{instance_id}-manual-{ts}"


def take_snapshot(rds, instance_id: str) -> str:
    snap_id = snapshot_id(instance_id)
    print(f"[+] Creating snapshot {snap_id}")
    rds.create_db_snapshot(DBSnapshotIdentifier=snap_id, DBInstanceIdentifier=instance_id)
    return snap_id


def prune_old(rds, instance_id: str, retention_days: int) -> int:
    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=retention_days)
    resp = rds.describe_db_snapshots(DBInstanceIdentifier=instance_id, SnapshotType="manual")
    removed = 0
    for snap in resp.get("DBSnapshots", []):
        created = snap["SnapshotCreateTime"]
        if created < cutoff:
            sid = snap["DBSnapshotIdentifier"]
            print(f"[-] Deleting old snapshot {sid} (created {created.isoformat()})")
            rds.delete_db_snapshot(DBSnapshotIdentifier=sid)
            removed += 1
    return removed


def instances_for_env(rds, env: str):
    result = []
    paginator = rds.get_paginator("describe_db_instances")
    for page in paginator.paginate():
        for inst in page["DBInstances"]:
            tags = {t["Key"]: t["Value"] for t in inst.get("TagList", [])}
            if tags.get("Environment") == env:
                result.append(inst["DBInstanceIdentifier"])
    return result


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--env", required=True, choices=["dev", "uat", "prod"])
    p.add_argument("--retention-days", type=int, default=7)
    p.add_argument("--region", default="ap-south-1")
    args = p.parse_args()

    rds = boto3.client("rds", region_name=args.region)
    instances = instances_for_env(rds, args.env)
    if not instances:
        print(f"No RDS instances tagged Environment={args.env}")
        return 0

    fail = 0
    for iid in instances:
        try:
            take_snapshot(rds, iid)
            n = prune_old(rds, iid, args.retention_days)
            print(f"[i] {iid}: pruned {n} old snapshots")
        except ClientError as e:
            print(f"[!] {iid}: {e}", file=sys.stderr)
            fail += 1
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())

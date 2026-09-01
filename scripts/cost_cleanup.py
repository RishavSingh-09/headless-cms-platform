#!/usr/bin/env python3
"""
cost_cleanup.py — Delete unattached EBS volumes, unused EIPs, and old snapshots
tagged with the given environment. Run in --dry-run first.

Usage:
  python cost_cleanup.py --env dev --dry-run
  python cost_cleanup.py --env dev
"""
import argparse
import datetime as dt
import sys

import boto3


def env_filter(env):
    return [{"Name": "tag:Environment", "Values": [env]}]


def cleanup_ebs(ec2, env, dry):
    resp = ec2.describe_volumes(Filters=[*env_filter(env), {"Name": "status", "Values": ["available"]}])
    for v in resp["Volumes"]:
        vid = v["VolumeId"]
        print(f"[EBS] unattached {vid} ({v['Size']} GiB)")
        if not dry:
            ec2.delete_volume(VolumeId=vid)


def cleanup_eip(ec2, env, dry):
    resp = ec2.describe_addresses(Filters=env_filter(env))
    for a in resp["Addresses"]:
        if "AssociationId" in a:
            continue
        alloc = a.get("AllocationId")
        print(f"[EIP] unassociated {a.get('PublicIp')} ({alloc})")
        if not dry and alloc:
            ec2.release_address(AllocationId=alloc)


def cleanup_snapshots(ec2, env, dry, older_than_days=30):
    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=older_than_days)
    resp = ec2.describe_snapshots(OwnerIds=["self"], Filters=env_filter(env))
    for s in resp["Snapshots"]:
        if s["StartTime"] < cutoff:
            sid = s["SnapshotId"]
            print(f"[SNAP] old {sid} ({s['StartTime'].date()})")
            if not dry:
                ec2.delete_snapshot(SnapshotId=sid)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--env", required=True)
    p.add_argument("--region", default="ap-south-1")
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    ec2 = boto3.client("ec2", region_name=args.region)
    print(f"Cleanup env={args.env} region={args.region} dry_run={args.dry_run}")
    cleanup_ebs(ec2, args.env, args.dry_run)
    cleanup_eip(ec2, args.env, args.dry_run)
    cleanup_snapshots(ec2, args.env, args.dry_run)
    return 0


if __name__ == "__main__":
    sys.exit(main())

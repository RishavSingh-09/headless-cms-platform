output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "rds_endpoint" { value = module.rds.endpoint }
output "media_bucket" { value = module.iam.media_bucket_name }

module "ec_labels" {
  source      = "git@github.com:3scale-sre/tf-aws-label.git?ref=tags/0.1.2"
  environment = local.environment
  project     = local.project
  workload    = local.workload
  type        = "ec"
  tf_config   = local.tf_config
}

resource "aws_elasticache_subnet_group" "ec_subnet" {
  name       = module.ec_labels.id
  subnet_ids = var.vpc_private_subnet_id
}

module "ec_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = module.ec_labels.id
  description         = "Security group for redis/valkey perf test"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["redis-tcp"]
  egress_rules        = ["all-all"]
  tags                = module.ec_labels.tags
}

resource "aws_elasticache_replication_group" "ec_redis" {
  description                 = "EC Redis for Valkey perf test"
  engine                      = "redis"
  subnet_group_name           = aws_elasticache_subnet_group.ec_subnet.name
  preferred_cache_cluster_azs = var.ec_preferred_az
  security_group_ids          = [module.ec_sg.this_security_group_id]
  replication_group_id        = format("%s-%s", module.ec_labels.id, "redis")
  node_type                   = var.ec_instance_type
  num_cache_clusters          = 1
  port                        = 6379
  engine_version              = "7.1"
  apply_immediately           = true
  tags                        = module.ec_labels.tags
}

resource "aws_elasticache_replication_group" "ec_valkey" {
  description                 = "EC Valkey perf test"
  engine                      = "valkey"
  subnet_group_name           = aws_elasticache_subnet_group.ec_subnet.name
  preferred_cache_cluster_azs = var.ec_preferred_az
  security_group_ids          = [module.ec_sg.this_security_group_id]
  replication_group_id        = format("%s-%s", module.ec_labels.id, "valkey")
  node_type                   = var.ec_instance_type
  num_cache_clusters          = 1
  port                        = 6379
  engine_version              = "7.2"
  apply_immediately           = true
  tags                        = module.ec_labels.tags
}

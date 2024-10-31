locals {
  project     = "eng"
  environment = "dev"
  workload    = "valkey-perf-test"
  tf_config   = "dev-eng-valkey-perf-test"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


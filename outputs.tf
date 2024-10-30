output "ec2_valkey_dns" {
  value = aws_instance.valkey_instance.private_ip
}

output "ec2_valkey_benchmark_dns" {
  value = aws_instance.valkey_benchmark_instance.private_ip
}

output "ec_redis_dns" {
  value = aws_elasticache_replication_group.ec_redis.primary_endpoint_address
}

output "ec_valkey_dns" {
  value = aws_elasticache_replication_group.ec_valkey.primary_endpoint_address
}

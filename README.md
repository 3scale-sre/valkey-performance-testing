# Valkey performance testing

This repository builds a simple environment to do some Valkey performance testing in AWS, comparing its performance among Valkey versions deployed on AWS EC2 or AWS Elasticache, as well as Redis.

You can update instances types in Terraform, as well as run the `valkey-benchmark` tool with different options, so you might arrive to different conclusions.

## Scenario

- All instances (either EC2 or Elasticache) are deployed on the same AWS Availability Zone `us-east-1a` (so there is no network difference affecting results)
- All instances share same instance type: EC2 `m7g.xlarge` and EC `cache.m7g.xlarge` with 4 cores. The reason to choose `m7g.xlarge`:
  - It has 4 cores, so valkey multithreading with io-threads can be tested
  - It is [one of the AWS Elasticache instance types](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/CacheNodes.SupportedTypes.html#CacheNodes.CurrentGen ) with 2 important features enabled: Enhanced I/O and Enhanced I/O Multiplexing, which theoretically applies to both latest Redis/Valkey:
    - **[+] Enhances I/O**
      ElastiCache for Redis optimizes compute utilization by handling network I/O on dedicated threads, allowing the Redis engine to focus on processing commands. By utilizing the extra CPU power available in nodes with four or more vCPUs, ElastiCache transparently delivers up to 83% increase in throughput and up to 47% reduction in latency per node. More details, see these links:
      https://aws.amazon.com/about-aws/whats-new/2019/03/amazon-elasticache-for-redis-503-enhances-io-handling-to-boost-performance/
      https://aws.amazon.com/blogs/database/boosting-application-performance-and-reducing-costs-with-amazon-elasticache-for-redis/

    - **[+] enhanced I/O multiplexing (Redis 7)**
      Enhanced I/O multiplexing, which delivers significant improvements to throughput and latency at scale. Enhanced I/O multiplexing is ideal for throughput-bound workloads with multiple client connections, and its benefits scale with the level of       workload concurrency.
      Each dedicated network I/O thread pipelines commands from multiple clients into the Redis engine, taking advantage of Redis' ability to efficiently process commands in batches. More details, see these links:
      https://aws.amazon.com/about-aws/whats-new/2023/02/enhanced-io-multiplexing-amazon-elasticache-redis/
      https://aws.amazon.com/blogs/database/enhanced-io-multiplexing-for-amazon-elasticache-for-redis/
- The same EC2 instance is used to run `valkey-benchmark` against the rest of instances
- The same EC2 instance is used to run both Valkey and Redis, but never at the same time
- It has been used latest availabe versions of each case at the time of publishing data:
  - Valkey EC2: 8.0.1
  - Redis EC2: 7.4 (latest stable)
  - Valkey Elasticache: 7.2 (introduced on 2 weeks ago)
  - Redis Elasticache: 7.1
- Valkey and Redis servers are running with same config changes compared to default config:
  - `--bind 0.0.0.0`: Change default interface to any (so db is available from outside the server)
  - `--protected-mode no`: Disable protected mode (so there is no auth, testing purpose)
  - `--save`: Disable SAVE (which can impact on performance)
  - `--io-threads 4`: Tune io-threads parameter to match number of instance CPUs (disabled by default). Only for valkey conf

## Benchmarks

#### EC2 Valkey 8.0.1 benchmark  io-threads 4
- Start valkey server on cpu 0, 1,2 and 3 (all cpus): 
```bash
taskset -c 0,1,2,3 ./valkey/src/valkey-server /valkey/valkey.conf --port 6379 --save --io-threads 4 --protected-mode no --bind 0.0.0.0
```
- Run benchmark on another EC2 instance (same AWS AZ): 
```bash
taskset -c 0,1,2,3 ./valkey/src/valkey-benchmark -h $EC2_PRIVATE_IP -t set -n 1000000 -c 250 -P 10 -r 50000000
```
- Results (I repeated several, added one of the best):
```
Summary:
  throughput summary: 964320.19 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        2.549     0.088     2.575     2.807     3.087     4.731
```

#### EC2 Redis 7.4 benchmark 
- Start redis server on cpu 0, 1,2 and 3 (all cpus): 
```bash
taskset -c 0,1,2,3 ./redis-stable/src/redis-server /redis-stable/redis.conf --port 6379 --save  --protected-mode no --bind 0.0.0.0
```
- Run benchmark on another EC2 instance (same AWS AZ): 
```bash
taskset -c 0,1,2,3 ./valkey/src/valkey-benchmark -h $EC2_PRIVATE_IP -t set -n 1000000 -c 250 -P 10 -r 50000000
```
- Results (I repeated several, added one of the best):
```
Summary:
  throughput summary: 726216.44 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        3.023     1.024     3.015     3.839     4.039     5.167
```

#### Elasticache Redis 7.1 benchmark 

- Run benchmark on another EC2 instance (same AWS AZ than Elasticache): 
```bash
taskset -c 0,1,2,3 ./valkey/src/valkey-benchmark -h $EC_PRIVATE_DNS -t set -n 1000000 -c 250 -P 10 -r 50000000
```
- Results (I repeated several, added one of the best):
```
Summary:
  throughput summary: 663129.94 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        3.143     0.752     3.303     4.719     5.103     5.983
```

#### Elasticache Valkey 7.2 benchmark 

- Run benchmark on another EC2 instance (same AWS AZ than Elasticache): 
```bash
taskset -c 0,1,2,3 ./valkey/src/valkey-benchmark -h $EC_PRIVATE_DNS -t set -n 1000000 -c 250 -P 10 -r 50000000
```
- Results (I repeated several, added one of the best):
```
Summary:
  throughput summary: 742390.50 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        2.923     0.824     2.951     4.087     4.335     4.871
```

## Conclusions

| Scenario  | Throughput (rps) |  Latency average (ms)| min  |  p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|---|
| Elasticache redis 7.1 | 663k  | 3.143   |  0.752   | 3.303  |4.719 | 5.103 | 5.983 |
| EC2 redis 7.4  | 726k  | 3.023  |  1.024 |3.015   |3.839 | 4.039  | 5.167 |
| Elasticache valkey 7.2 | 742k  | 2.923   | 0.824   | 2.951   |4.087 | 4.335  | 4.871 |
| EC2 valkey 8 io-threds 4 |  946k  | 2.549  |  0.088  | 2.575 | 2.807  |3.087 |  4.731 |

 
- Worst performance is redis (either EC2 and Elasticache)
- `EC2-redis-v7.4` has +10% throughput than `EC-redis-v7.1`, possibly due to being newer redis version. Some latencies on EC-redis are a bit better, some not, in general they look similar
- `Elasticache-valkey-v7.2` is just a bit better than the other 2 redis cases in terms of throughput, and a bit better on most latencies, but very similar too. Theoretically `Elasticache-Valkey-v7.2` is mainly a rebranded `redis 7.2`, so probably is expected
  - Actually, AWS puts lots of efforts on making easier the migration from Elasticache redis to Elasticahe valkey, making even possible to re-use possible current Elasticache redis instance reserves
- `EC2-Valkey-v8.0.1` definitely has the greatest performance, which is the first real Valkey release. Doing a comparison with `EC2-Redis-v7.4`:
  - Throughout: +34%
  - Latency average: -15%
  - Latency min: -91%
  - Latency p50: -15%
  - Latency p95: -26%
  - Latency p99: -23%
  - Latency max: -8%
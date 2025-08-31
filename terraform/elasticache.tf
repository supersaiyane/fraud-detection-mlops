resource "aws_elasticache_subnet_group" "fraud_cache" {
  name       = "${var.project}-fraud-cache-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "fraud_cache" {
  cluster_id           = "${var.project}-fraud-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.fraud_cache.name
  security_group_ids   = [var.security_group_id]

  tags = {
    Project = var.project
    Purpose = "FraudCache"
  }
}

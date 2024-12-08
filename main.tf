resource "aws_vpc" "mwaa_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mwaa-vpc"
  }
}

# Public subnet for NAT Gateway
resource "aws_subnet" "mwaa_subnet_public" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mwaa-public-subnet"
  }
}

resource "aws_subnet" "mwaa_subnet_private1" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "mwaa-private-subnet-1"
  }
}

resource "aws_subnet" "mwaa_subnet_private2" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "mwaa-private-subnet-2"
  }
}

resource "aws_internet_gateway" "mwaa_igw" {
  vpc_id = aws_vpc.mwaa_vpc.id

  tags = {
    Name = "mwaa-igw"
  }
}

# EIP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "mwaa_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.mwaa_subnet_public.id

  tags = {
    Name = "mwaa-nat"
  }

  depends_on = [aws_internet_gateway.mwaa_igw]
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mwaa_igw.id
  }

  tags = {
    Name = "mwaa-public-rt"
  }
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mwaa_nat.id
  }

  tags = {
    Name = "mwaa-private-rt"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.mwaa_subnet_public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.mwaa_subnet_private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.mwaa_subnet_private2.id
  route_table_id = aws_route_table.private.id
}

# VPC Endpoints
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.mwaa_vpc.id
  service_name = "com.amazonaws.ap-southeast-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name = "mwaa-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.mwaa_vpc.id
  service_name       = "com.amazonaws.ap-southeast-2.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.mwaa_subnet_private1.id, aws_subnet.mwaa_subnet_private2.id]
  security_group_ids = [aws_security_group.mwaa_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.mwaa_vpc.id
  service_name       = "com.amazonaws.ap-southeast-2.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.mwaa_subnet_private1.id, aws_subnet.mwaa_subnet_private2.id]
  security_group_ids = [aws_security_group.mwaa_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id             = aws_vpc.mwaa_vpc.id
  service_name       = "com.amazonaws.ap-southeast-2.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.mwaa_subnet_private1.id, aws_subnet.mwaa_subnet_private2.id]
  security_group_ids = [aws_security_group.mwaa_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id             = aws_vpc.mwaa_vpc.id
  service_name       = "com.amazonaws.ap-southeast-2.monitoring"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.mwaa_subnet_private1.id, aws_subnet.mwaa_subnet_private2.id]
  security_group_ids = [aws_security_group.mwaa_sg.id]
  private_dns_enabled = true
}

resource "aws_s3_bucket" "mwaa_bucket" {
  bucket_prefix = "mwaa-dags"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "mwaa_bucket_versioning" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "mwaa_bucket_public_access_block" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload requirements.txt to S3
resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  key    = "requirements.txt"
  source = "${path.module}/requirements.txt"
  etag   = filemd5("${path.module}/requirements.txt")
}

resource "aws_mwaa_environment" "mwaa_environment" {
  name = "minimal-mwaa-environment"

  airflow_configuration_options = {
    "core.default_task_retries" = 1
    "secrets.backend"           = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
    "secrets.backend_kwargs"    = "{\"connections_prefix\": \"airflow/connections\", \"variables_prefix\": \"airflow/variables\", \"region_name\": \"ap-southeast-2\"}"
  }

  dag_s3_path        = "dags/"
  requirements_s3_path = "requirements.txt"
  execution_role_arn = aws_iam_role.mwaa_execution_role.arn

  environment_class = "mw1.small"

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  max_workers = 1
  min_workers = 1

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = [aws_subnet.mwaa_subnet_private1.id, aws_subnet.mwaa_subnet_private2.id]
  }

  source_bucket_arn = aws_s3_bucket.mwaa_bucket.arn
  
  webserver_access_mode = "PUBLIC_ONLY"

  depends_on = [
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.logs,
    aws_vpc_endpoint.monitoring
  ]
} 
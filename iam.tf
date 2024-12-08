resource "aws_iam_role" "mwaa_execution_role" {
  name_prefix = "mwaa-execution-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = ["airflow.amazonaws.com", "airflow-env.amazonaws.com"]
      }
    }]
  })
}

resource "aws_iam_role_policy" "mwaa_policy" {
  name = "mwaa-policy"
  role = aws_iam_role.mwaa_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "airflow:*",
        "s3:*",
        "logs:*",
        "cloudwatch:*",
        "secretsmanager:*"
      ]
      Resource = ["*"]
    }]
  })
}

resource "aws_security_group" "mwaa_sg" {
  name        = "mwaa-security-group"
  description = "Security group for MWAA environment"
  vpc_id      = aws_vpc.mwaa_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 
resource "aws_secretsmanager_secret" "airflow_variable" {
  name_prefix                    = "airflow/variables/test_var-"
  description                    = "Test variable for Airflow"
  force_overwrite_replica_secret = true
  recovery_window_in_days        = 0
}

resource "aws_secretsmanager_secret_version" "airflow_variable" {
  secret_id     = aws_secretsmanager_secret.airflow_variable.id
  secret_string = "hello from secrets manager"
} 
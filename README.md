# MWAA

Create AWS profile

Login to AWS

```bash
aws sso login
```

Create the state resources:

```bash
cd bootstrap
terraform init
terraform apply
```

Create MWAA

```bash
cd ..
terraform init
```

Upload DAGs to your MWAA S3 bucket:

```bash
aws s3 cp dags/*.py s3://$(terraform output -raw mwaa_bucket_name)/dags/
```
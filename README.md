# MWAA DAGs Upload

Upload DAGs to your MWAA S3 bucket:

```bash
aws s3 cp dags/*.py s3://$(terraform output -raw mwaa_bucket_name)/dags/
```
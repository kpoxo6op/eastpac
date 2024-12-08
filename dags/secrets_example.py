from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.models import Variable
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'variables_example',
    default_args=default_args,
    description='Example DAG using Variables from AWS Secrets Manager',
    schedule_interval=timedelta(days=1),
    catchup=False
)

def use_variables():
    # Get a single variable from AWS Secrets Manager
    test_var = Variable.get("test_var")
    print(f"Successfully read variable: {test_var}")

use_variables_task = PythonOperator(
    task_id='use_variables',
    python_callable=use_variables,
    dag=dag
) 
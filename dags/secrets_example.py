from airflow import DAG
from airflow.operators.bash import BashOperator
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
    description='Test DAG with Bash',
    schedule_interval=timedelta(days=1),
    catchup=False
)

test_task = BashOperator(
    task_id='test_task',
    bash_command='echo "Testing task execution" && date',
    dag=dag
) 
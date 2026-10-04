from datetime import datetime

from airflow.sdk import DAG
from airflow.providers.docker.operators.docker import DockerOperator

import os

dbt_env = {
            "DATABASE_HOST": os.environ["DATABASE_HOST"],
            "DATABASE_PORT": os.environ["DATABASE_PORT"],
            "DATABASE_USER": os.environ["DATABASE_USER"],
            "DATABASE_PASSWORD": os.environ["DATABASE_PASSWORD"],
            "DATABASE_NAME": os.environ["DATABASE_NAME"],
            }

dbt_mount = [{"target": "/app", "source": f"{os.environ['PROJECT_ROOT']}/dbt", "type": "bind"}]

with DAG(dag_id = "olist_dbt_transform", start_date=datetime(2026,1,1), schedule=None, catchup=False) as dag:
    dbt_run = DockerOperator(task_id = 'dbt_run', 
                              image ='olist-data-dbt', 
                              command = 'dbt run',
                              docker_url = 'unix://var/run/docker.sock',
                              mounts = dbt_mount,
                              network_mode="olist-data_default",
                              environment=dbt_env,                          
                              auto_remove = 'force',
                              mount_tmp_dir = False)

    dbt_test = DockerOperator(task_id = 'dbt_test', 
                              image ='olist-data-dbt', 
                              command = 'dbt test',
                              docker_url = 'unix://var/run/docker.sock',
                              mounts = dbt_mount,
                              network_mode="olist-data_default",
                              environment=dbt_env,                          
                              auto_remove = 'force',
                              mount_tmp_dir = False)

    dbt_run >> dbt_test
from datetime import datetime

from airflow.sdk import DAG
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator

import os

python_env = {
            "DATABASE_HOST": os.environ["DATABASE_HOST"],
            "DATABASE_PORT": os.environ["DATABASE_PORT"],
            "DATABASE_USER": os.environ["DATABASE_USER"],
            "DATABASE_PASSWORD": os.environ["DATABASE_PASSWORD"],
            "DATABASE_NAME": os.environ["DATABASE_NAME"],
            "KAGGLEHUB_CACHE": os.environ["KAGGLEHUB_CACHE"],
            }
python_mount = [{"target": "/app/src", "source": f"{os.environ['PROJECT_ROOT']}/python/src", "type": "bind"},
                {"target": "/app/data", "source": f"{os.environ['PROJECT_ROOT']}/data", "type": "bind"}
                ]

with DAG(dag_id = "olist_ingestion", start_date=datetime(2026,1,1), schedule="@daily", catchup=False) as dag:
    extract_py = DockerOperator(task_id="extract",
                              image="olist-data-python",
                              command="python /app/src/extract_pipeline.py",
                              docker_url="unix://var/run/docker.sock",
                              network_mode="olist-data_default",
                              environment=python_env,
                              mounts=python_mount,
                              auto_remove="force",
                              mount_tmp_dir=False,
                            )

    load_py = DockerOperator(task_id="load",
                              image="olist-data-python",
                              command="python /app/src/load_pipeline.py",
                              docker_url="unix://var/run/docker.sock",
                              network_mode="olist-data_default",
                              environment=python_env,
                              mounts=python_mount,
                              auto_remove="force",
                              mount_tmp_dir=False,
                            )

    trigger_dbt = TriggerDagRunOperator(
        task_id="trigger_dbt_pipeline",
        trigger_dag_id="olist_dbt_transform",
    )

    extract_py >> load_py >> trigger_dbt
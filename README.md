# Olist Analytics Engineering Pipeline Project

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Data Source](#data-source)
- [Project Structure](#project-structure)
- [Pipeline Workflow](#pipeline-workflow)
  - [Data Extraction](#data-extraction)
  - [Data Loading](#data-loading)
  - [Data Transformation](#data-transformation)
  - [Data Quality Testing](#data-quality-testing)
  - [Airflow Orchestration](#airflow-orchestration)
- [Docker Architecture](#docker-architecture)
- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Environment Variables](#environment-variables)
  - [Start the Project](#start-the-project)
  - [Airflow](#airflow)
- [Usage](#usage)
    - [Run the Pipeline](#run-the-pipeline)
    - [Run Individual Components](#run-individual-components)
    - [Scheduling](#scheduling)
    - [dbt Documentation](#dbt-documentation)
- [Design Decisions](#design-decisions)
- [Limitations](#limitations)
- [Future Improvements](#future-improvements)
- [AI Assistance](#ai-assistance)
- [License](#license)

## Overview
This is an end-to-end analytics engineering project that extracts the Brazilian Olist E-Commerce dataset from Kaggle and loads into PostgreSQL with Python, transforms the raw data into analytics-ready datasets with dbt, and orchestrates the workflows with Apache Airflow.

The project is fully containerized with Docker Compose, with separate containers for Python, PostgreSQL, dbt, and Airflow.  

## Architecture
```text
Kaggle
   │
   ▼
Python Extract & Validate
   │
   ▼
CSV Files
   │
   ▼
Python Load & Validate
   │
   ▼
PostgreSQL Raw Layer
   │
   ▼
dbt Transformation
   ├── Staging
   ├── Intermediate
   └── Marts
        │
        ▼
    dbt Tests
        │
        ▼
 Analytics Data

Airflow
   ├── orchestrates Python ingestion
   └── triggers dbt transformation
```

The application components run in Docker containers and communicate through the Docker Compose network.

## Tech Stack
- **Python:** data extraction, file validation, and PostgreSQL ingestion
- **Pandas:** CSV processing
- **KaggleHub:** downloading datasets from Kaggle
- **PostgreSQL:** raw data storage and transformed data warehouse
- **SQLAlchemy:** PostgreSQL connectivity and database operations
- **dbt:** SQL-based data transformation, testing, and documentation
- **Apache Airflow:** workflow orchestration and scheduling
- **Docker / Docker Compose:** containerization and local environment management

## Data Source
The project uses the Brazilian E-Commerce Public Dataset by Olist from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data).

## Project Structure
```text
olist-data/
│
├── docker-compose.yml
│
├── .env.example
│
├── .gitignore
│
├── python/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── src
|       ├── config.py
|       ├── database.py
|       ├── extract.py
│       ├── extract_pipeline.py
│       ├── load.py
│       ├── load_pipeline.py
│       └── validate.py
│
├── dbt
│   ├── Dockerfile
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   ├── package-lock.yml
│   ├── models
|   |   ├── staging/
|   |   ├── intermediate/  
|   |   └── marts
|   |       ├── core/
|   |       └── reporting/
│   └── seeds
|       ├── brazil_floating_holidays.csv
|       ├── brazil_floating_holidays.yml
|       ├── category_name_translation_overrides.csv
|       └── category_name_translation_overrides.yml
|
├── airflow
│   ├── Dockerfile
│   └── dags
|       ├── ingestion_pipeline.py
|       └── dbt_pipeline.py 
│
└── README.md
```

## Pipeline Workflow

### Data Extraction
The Python extraction pipeline downloads the source CSV files from Kaggle using KaggleHub. Each downloaded file is validated before it is loaded to PostgreSQL.

The extraction process checks that:
- The downloaded file exists.
- The file is not empty.
- The CSV can be read by Pandas.
- The resulting DataFrame contains data rows.
- The file does not contain duplicate column names.
- The file contains the expected columns.

Validation failures raise exceptions, causing the Airflow task to fail and preventing downstream processing.

### Data Loading
Validated CSV files are loaded into the PostgreSQL raw schema. 

The project currently uses a full-refresh loading strategy:
```text
Does raw table exist?
       │
    ┌──┴──┐
   No     Yes
   │       │
CREATE   TRUNCATE
TABLE      │
   │       │
   └───┬───┘
       ▼
     INSERT
```

The loading process checks that:
- The target table exists in the expected PostgreSQL schema.
- The row count of the PostgreSQL table matches the number of rows in the source DataFrame.

The loading process runs within a single database transaction. If any table fails to load or validate, the transaction is rolled back, preventing a partially refreshed raw layer.

The raw tables are loaded and validated before dbt transformations are executed, so downstream models operate only on a successfully ingested snapshot.

### Data Transformation
dbt transforms the raw tables into analytics-ready datasets.

The dbt project follows a layered modeling approach.
- **Seeds:** Stores reference datasets for the transformation models, including Brazilian floating holidays and Category name translation overrides.
- **Staging:** Standardizes the column names, formats, and data types.
- **Intermediate:** Combines and transforms staging models to implement reusable business logic. This includes deduplicating the geolocation data and determining each customer's latest address based on their most recent order.
- **Marts:** Builds dimensional and fact models for analytics. This includes:
    - **Customer dimension:** Contains each customer's latest address and lifetime purchase metrics.
    - **Date dimension:** Provides a continuous series of dates with calendar attributes, weekend and standard holiday flags, and prior-year reference dates.
    - **Geolocation dimension:** Contains the 5-digit zip code prefix, corresponding city and state, and the coordinates.
    - **Product dimension:** Contains product category name, product name and description length, photo count, product dimensions, and weight. 
    - **Seller dimension:** Contains the seller shipping address, including the 5-digit zip code prefix, city, and state.
    - **Order item fact:** Provides orderitem-level revenue metrics, shipping limit date, and shipping distance.
    - **Order fact:** Provides order-level fulfillment lifecycle information, revenue metrics, payment information, and review score.

### Data Quality Testing
dbt tests are executed after the transformations are built to verify the configured data quality expectations.

The Python ingestion pipeline also performs source file and raw table validation before dbt runs.

dbt tests are performed at each modeling layer, with progressively more business-oriented validation as the data moves downstream.
- **Staging:** Validates source-level data quality, including unique and non-null primary keys, accepted ranges for numeric fields, and valid values for categorical fields.
- **Intermediate:** Validates the integrity of the transformed datasets, including unique and non-null primary keys.
- **Marts:** Validates business rules and relationships between metrics and events. Examples include verifying that product subtotal plus freight fee equals total revenue and that the order lifecycle follows the expected sequence, such as an order being placed before it is accepted.

### Airflow Orchestration
This project uses two separate Airflow DAGs.

**Ingestion DAG**
```text
olist_ingestion
     ↓
  extract
     ↓
   load
     ↓
trigger dbt DAG
```
The ingestion DAG is responsible for:
- Downloading source data
- Validating source files
- Loading raw PostgreSQL tables
- Validating loaded tables
- Triggering the downstream dbt workflow

**dbt Transform DAG**
```text
olist_dbt_transform
        ↓
     dbt run
        ↓
     dbt test
```
The dbt DAG is responsible for:
- Building dbt models
- Running dbt data quality tests

## Docker Architecture
Docker Compose manages the project's services.
```Text
Docker Compose 
│ 
├── PostgreSQL 
│     └── Application database 
│ 
├── Python
│     └── Data ingestion
│ 
├── dbt 
│     └── Data transformation 
│ 
├── Airflow PostgreSQL
│     └── Airflow metadata database
│
└── Airflow 
      ├── API Server 
      ├── Scheduler
      └── DAG Processor
```
The Python and dbt containers are separate environments so that their dependencies can be managed independently.

Airflow uses DockerOperator to execute the Python and dbt workloads in their respective containers.

The project uses a shared Docker network so that containers can communicate using Docker service names such as `db`.

## Setup

### Prerequisites
- Docker  
- Docker Compose  

### Environment Variables
Create a local `.env` file from the provided example:

```bash
cp .env.example .env
```

Configure the required database and Airflow-related environment variables in `.env`.

The `.env` file contains local configuration and credentials and is intentionally excluded from version control.

### Start the Project
Build and start the Docker services:

```bash
docker compose up -d --build
```

Check the running services:

```bash
docker compose ps
```

### Airflow
Open the Airflow web interface:

http://localhost:8080

From the Airflow UI, the ingestion and dbt DAGs can be monitored and manually triggered.

## Usage

### Run the Pipeline
The intended workflow is:

1. Trigger or schedule ingestion_pipeline
2. Download source data
3. Validate source files
4. Load PostgreSQL raw tables
5. Validate loaded tables
6. Trigger dbt_pipeline
7. Run dbt models
8. Run dbt tests

### Run Individual Components
Both the ingestion DAG and the dbt DAG can be triggered independently from the Airflow UI.

### Scheduling

The ingestion DAG is responsible for initiating the end-to-end workflow.

The dbt DAG is triggered by the ingestion DAG rather than using an independent schedule.

This ensures that transformations run after the raw data has been refreshed.

### dbt Documentation
dbt documentation can be generated from the dbt project and served locally.

After starting the Docker environment:

```bash
docker compose exec dbt dbt docs generate
```

The generated documentation can then be served with:
```bash
docker compose exec dbt dbt docs serve --host 0.0.0.0
```
Open the dbt documentation web interface:

http://localhost:8081

The dbt documentation provides information about the project's models, columns, tests, and lineage.

## Design Decisions
### Separate Ingestion and Transformation DAGs
The project separates ingestion and transformation into two DAGs.

This allows each workflow to be developed and tested independently while still supporting an end-to-end pipeline through Airflow DAG triggering.

### Separate Docker Containers
Python, PostgreSQL, dbt, and Airflow run in separate containers.

This provides isolation between environments and makes dependencies explicit and reproducible.

### Full-Refresh Raw Loading
The current ingestion strategy performs a full refresh of raw tables.

This keeps the ingestion logic relatively simple and matches the snapshot-oriented nature of the source dataset.

An incremental ingestion strategy would be more appropriate for a source that provides reliable change tracking or incremental updates.

### Validation Before Transformation
Source validation and raw-table validation occur before dbt runs.

This prevents transformation jobs from operating on files or tables that do not meet the expected structural requirements.

## Limitations
- The source dataset is currently processed using a full-refresh strategy.
- The pipeline is designed primarily for local Docker execution.
- Monitoring and alerting are not currently implemented.

## Future Improvements
- Add reporting models and dashboard examples.
- Add reusable generic dbt tests for common data quality rules.
- Add pipeline monitoring and alerting.
- Add incremental ingestion if the source becomes incrementally available.

## AI Assistance
AI tools were used as a development aid throughout the project, including for exploring implementation approaches, troubleshooting errors, reviewing code, and improving documentation.

## License
This project is intended for educational and portfolio purposes.
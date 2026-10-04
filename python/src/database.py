from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from config import get_database_config

def connect_to_database() -> Engine:
    """
    Create database connection engine
    
    Returns:
        engine: the database connection engine
    """
    db_user, db_password, db_host, db_port, db_name = get_database_config()
    connection_url = f"postgresql+psycopg://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

    engine = create_engine(connection_url)

    return engine

def create_schema(engine: Engine, schema_name: str):
    """
    Create a database schema if not exist

    Args:
        engine: the databse connection engine
        schema_name: str, the name of the database schema
    """
    "CREATE SCHEMA IF NOT EXIST"

    with engine.connect() as connection:
        connection.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name};"))
        connection.commit()
#load into the PostgreSQL database
from pathlib import Path
import pandas as pd
from sqlalchemy import Connection, inspect, text

def read_file(file_name:str) -> pd.DataFrame:
    """Read a CSV file from the data folder as a pandas DataFrame.

    Args:
        file_name: Name of the CSV file in /app/data.

    Returns:
        Data loaded from the CSV file.
    """
    data_dir = Path("/app/data")
    return pd.read_csv(data_dir / file_name)

def full_refresh_table(
    df: pd.DataFrame, 
    connection: Connection, 
    schema_name: str, 
    table_name: str
) -> None:
    """Fully refresh a PostgreSQL table with DataFrame data

    If the target table already exists, all existing rows are removed
    and the DataFrame is appended. If the target table does not exist,
    pandas creates the table and inserts the DataFrame data.

    Args:
        df: Data to load into the PostgreSQL table.
        connection: PostgreSQL database connection.
        schema_name: Name of the target database schema.
        table_name: Name of the target database table.
    """
    inspector = inspect(connection)

    if inspector.has_table(table_name, schema=schema_name):
        #subsequent full refresh
        connection.execute(
            text(
                f'TRUNCATE TABLE "{schema_name}"."{table_name}"'
                )
            )
        
        df.to_sql(
            schema = schema_name,
            name = table_name,
            con=connection,
            if_exists = "append",
            index = False,
        )

    else:
        #first load
        df.to_sql(
            schema = schema_name,
            name = table_name,
            con=connection,
            if_exists = "fail",
            index = False,
        )
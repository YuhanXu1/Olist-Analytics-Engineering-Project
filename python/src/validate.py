import pandas as pd
from pathlib import Path
from sqlalchemy import Connection, inspect, text

def validate_file_exists(file_path: Path) -> None:
    """validate that a file exists.

    Args:
        file_path: Path to the file to validate.

    Raises:
        FileNotFoundError: If the path does not exist or is not a file.
    """
    if not file_path.is_file():
        raise FileNotFoundError(
            f"Downloaded file was not found: {file_path}"
        )

def validate_file_not_empty(file_path: Path) -> None:
    """Validate that a file contains data.

    Args:
        file_path: Path to the file to validate.

    Raises:
        ValueError: If the file exists but has zero bytes.
    """
    if file_path.stat().st_size == 0:
        raise ValueError(
            f"Downloaded file is empty: {file_path}"
        )

def validate_dataframe_not_empty(
    df: pd.DataFrame,
    file_path: str,
) -> None:
    """Validate that a DataFrame contains at least one row.

    Args:
        df: DataFrame to validate.
        file_path: Source file associated with the DataFrame.

    Raises:
        ValueError: If the DataFrame contains no rows.
    """
    if df.empty:
        raise ValueError(
            f"Downloaded file contains no data rows: {file_path}"
        )

def validate_duplicate_columns(
    df: pd.DataFrame,
    file_path: str,
) -> None:
    """Validate that there is no duplicated columns.
    
    Args:
        df: DataFrame to validate.
        file_path: Source file associated with the DataFrame.

    Raises:
        ValueError: If the DataFrame contains duplicated columns.
    """
    if df.columns.duplicated().any():
        duplicated_columns = df.columns[df.columns.duplicated()].tolist()
        raise ValueError(
            f"{file_path} contains duplicate columns: {duplicated_columns}"
        )

def validate_expected_columns(
    df: pd.DataFrame,
    file_path: str,
    expected_columns: list[str],
) -> None:
    """Validate that a DataFrame has exactly the expected columns.
    
    Args:
        df: DataFrame to validate.
        file_path: Source file associated with the DataFrame.
        expected_columns: Columns required by the downstream pipeline.

    Raises:
        ValueError: If the DataFrame is missing expected columns, or contains unexpected columns"""
    expected = set(expected_columns)
    actual = set(df.columns)

    missing_columns = expected - actual
    extra_columns = actual - expected

    if missing_columns or extra_columns:
        errors = []

        if missing_columns:
            errors.append(
                f"missing expected columns: {sorted(missing_columns)}"
            )

        if extra_columns:
            errors.append(
                f"unexpected extra columns: {sorted(extra_columns)}"
            )

        raise ValueError(
            f"{file_path} has an invalid schema: "
            + "; ".join(errors)
        )

def validate_table_exists(
    connection: Connection,
    schema_name: str,
    table_name: str,
) -> None:
    """Validate that a table exists in a PostgreSQL schema.

    Args:
        connection: PostgreSQL database connection.
        schema_name: Name of the database schema.
        table_name: Name of the table.

    Raises:
        ValueError: If the table does not exist in the specified schema.
    """
    inspector = inspect(connection)

    if not inspector.has_table(table_name, schema=schema_name):
        raise ValueError(
            f"Table does not exist: {schema_name}.{table_name}"
        )

def validate_row_count(
    connection: Connection, 
    df: pd.DataFrame, 
    schema_name: str, 
    table_name: str
) -> None:
    """Validate that the row count for loaded table matches the DataFrame.

    Args:
        connection: PostgreSQL database connection.
        df: DataFrame to validate against.
        schema_name: Name of the database schema.
        table_name: Name of the table.
    
    Raises:
        ValueError: If the row count does not match.
    """
    expected_count = len(df)

    row_query = text(f'SELECT COUNT(*) FROM "{schema_name}"."{table_name}"')
    actual_count = connection.execute(row_query).scalar()

    if actual_count != expected_count:
        raise ValueError(
            f"Row count mismatch for {schema_name}.{table_name}: "
            f"expected {expected_count}, found {actual_count}."
        )
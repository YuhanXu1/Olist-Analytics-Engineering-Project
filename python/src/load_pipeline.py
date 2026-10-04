import logging

from database import connect_to_database, create_schema
from load import read_file, full_refresh_table
from config import table_mapping, db_schema_name
from validate import (
    validate_dataframe_not_empty, 
    validate_table_exists, 
    validate_row_count
)

logger = logging.getLogger(__name__)

def load_pipeline()-> None:
    engine = connect_to_database()

    logger.info("Creating schema %s...", db_schema_name)
    create_schema(engine, db_schema_name)
    logger.info("Successfully created schema %s...", db_schema_name)

    with engine.begin() as connection:
        for file_name, table_config in table_mapping.items():
            df = read_file(file_name)
            table_name=table_config["table_name"]

            validate_dataframe_not_empty(df, file_name)

            logger.info(
                "Loading %s into %s.%s",
                file_name,
                db_schema_name,
                table_name,
            )
            
            full_refresh_table(
                df=df,
                connection=connection,
                schema_name=db_schema_name,
                table_name=table_name,
            )

            logger.info(
                "Validating %s.%s...",
                db_schema_name,
                table_name,
            )

            validate_table_exists(
                connection=connection, 
                schema_name=db_schema_name,
                table_name=table_name,
            )

            validate_row_count(
                connection=connection,
                df=df,
                schema_name=db_schema_name,
                table_name=table_name,
            )

            logger.info(
                "Successfully loaded %s rows into %s.%s",
                len(df),
                db_schema_name,
                table_name,
            )

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    load_pipeline()
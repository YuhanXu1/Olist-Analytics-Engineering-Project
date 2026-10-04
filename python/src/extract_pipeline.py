import logging
import pandas as pd

from extract import download_raw_file
from config import table_mapping, dataset_name
from validate import (
    validate_file_exists, 
    validate_file_not_empty, 
    validate_dataframe_not_empty,
    validate_duplicate_columns,
    validate_expected_columns
)

logger = logging.getLogger(__name__)

def extract_pipeline() -> None:
    for file_name, table_config in table_mapping.items():
        logger.info("Downloading %s...", file_name)
        
        file_path = download_raw_file(dataset_name, file_name)

        logger.info("Validating %s...", file_name)

        validate_file_exists(file_path)
        validate_file_not_empty(file_path)

        df = pd.read_csv(file_path)
        validate_dataframe_not_empty(df, file_path)
        validate_duplicate_columns(df, file_path)
        validate_expected_columns(df, file_path, table_config["expected_columns"])

        logger.info(
            "Successfully extracted and validated %s.",
            file_name,
        )

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    extract_pipeline()
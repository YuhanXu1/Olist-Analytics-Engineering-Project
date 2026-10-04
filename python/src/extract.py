import kagglehub
from pathlib import Path

def download_raw_file(dataset_name: str, file_name: str) -> Path:
    """Download a raw file from Kaggle dataset to the data folder inside the container.

    Args:
        dataset_name: Name of the Kaggle dataset.
        file_name: Name of the specific file to download.

    Returns:
        Path to the downloaded file.
    """
    data_dir = Path("/app/data")

    file_path = kagglehub.dataset_download(
        dataset_name,
        path=file_name,
        output_dir=data_dir,
    )
    return Path(file_path)
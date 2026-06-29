from collections import Counter
from pathlib import Path

from pydantic import BaseModel


SUPPORTED_FILE_EXTENSIONS = {
    ".asmx",
    ".config",
    ".cs",
    ".csproj",
    ".dbml",
    ".docx",
    ".feature",
    ".json",
    ".pdf",
    ".postman_collection",
    ".postman_collection_20151009",
    ".scmp",
    ".svc",
    ".sql",
    ".sqlproj",
    ".txt",
    ".wsdl",
    ".xaml",
    ".xlsx",
    ".xlsm",
    ".xml",
    ".xsd",
}


class DataSourceInventory(BaseModel):
    """Recursive inventory of source files available for semantic extraction."""

    root_folder_path: str
    total_files: int
    supported_files_count: int
    file_type_counts: dict[str, int]
    supported_file_paths: list[str]


def build_data_source_inventory(data_folder_path: Path) -> DataSourceInventory:
    """Scan a data folder recursively and classify supported source files."""
    discovered_file_paths = sorted(
        file_path for file_path in data_folder_path.rglob("*") if file_path.is_file()
    )
    file_type_counter = Counter(
        file_path.suffix.lower() or "<no_extension>"
        for file_path in discovered_file_paths
    )
    supported_file_paths = [
        file_path.relative_to(data_folder_path).as_posix()
        for file_path in discovered_file_paths
        if file_path.suffix.lower() in SUPPORTED_FILE_EXTENSIONS
    ]

    return DataSourceInventory(
        root_folder_path=str(data_folder_path),
        total_files=len(discovered_file_paths),
        supported_files_count=len(supported_file_paths),
        file_type_counts=dict(file_type_counter),
        supported_file_paths=supported_file_paths,
    )

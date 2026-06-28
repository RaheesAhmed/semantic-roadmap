from pathlib import Path

from semantic_roadmap.inventory.data_source_inventory import build_data_source_inventory


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[2]


def test_build_data_source_inventory_discovers_supported_files_recursively() -> None:
    data_folder_path = PROJECT_ROOT_PATH / "data"

    data_source_inventory = build_data_source_inventory(data_folder_path)

    assert data_source_inventory.total_files >= 974
    assert data_source_inventory.file_type_counts[".sql"] == 972
    assert data_source_inventory.file_type_counts[".docx"] == 1
    assert data_source_inventory.file_type_counts[".pdf"] == 1
    assert data_source_inventory.supported_files_count >= 974


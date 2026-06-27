from pathlib import Path

from semantic_roadmap.sql_inventory_builder import build_sql_inventory


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[1]


def test_build_sql_inventory_counts_database_object_groups() -> None:
    crm_database_folder_path = PROJECT_ROOT_PATH / "data" / "CRM.Db"

    sql_inventory = build_sql_inventory(crm_database_folder_path)

    assert sql_inventory.total_sql_files == 972
    assert sql_inventory.object_group_counts["dbo/Tables"] == 139
    assert sql_inventory.object_group_counts["spq/Stored Procedures"] == 502
    assert "dbo/Tables/eBooking.sql" in sql_inventory.sample_object_paths

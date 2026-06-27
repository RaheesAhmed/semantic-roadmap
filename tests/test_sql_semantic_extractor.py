from pathlib import Path

from semantic_roadmap.sql_semantic_extractor import (
    extract_stored_procedure_summary,
    extract_table_summary,
)


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[1]


def test_extract_table_summary_reads_columns_indexes_and_descriptions() -> None:
    table_file_path = PROJECT_ROOT_PATH / "data" / "CRM.Db" / "dbo" / "Tables" / "eBooking.sql"

    table_summary = extract_table_summary(table_file_path)

    assert table_summary.schema_name == "dbo"
    assert table_summary.table_name == "eBooking"
    assert len(table_summary.columns) >= 40
    assert table_summary.primary_key_columns == ["RowID"]
    assert "PI_eBooking_01" in table_summary.index_names
    assert table_summary.column_descriptions["wUseTravelPkg"] == "是否選擇旅遊套票"
    assert table_summary.columns[0].column_name == "RowID"
    assert table_summary.columns[0].data_type == "BIGINT"


def test_extract_stored_procedure_summary_reads_parameters_fields_and_dependencies() -> None:
    procedure_file_path = (
        PROJECT_ROOT_PATH
        / "data"
        / "CRM.Db"
        / "spq"
        / "Stored Procedures"
        / "GetBookingRoom.sql"
    )

    procedure_summary = extract_stored_procedure_summary(procedure_file_path)

    assert procedure_summary.schema_name == "spq"
    assert procedure_summary.procedure_name == "GetBookingRoom"
    assert procedure_summary.parameters["@pRowID"] == "BIGINT"
    assert "dbo.eBookingRoom" in procedure_summary.referenced_tables
    assert "wBookingRid" in procedure_summary.selected_fields
    assert "wOldBookingStatus" in procedure_summary.selected_fields

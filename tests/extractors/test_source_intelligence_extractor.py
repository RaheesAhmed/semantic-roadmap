from pathlib import Path

from openpyxl import Workbook

from semantic_roadmap.extractors.source.source_intelligence_extractor import (
    extract_source_file_summaries,
)
from semantic_roadmap.security.file_ingestion_policy import classify_source_file_path


def test_classify_source_file_path_skips_sensitive_and_noise_files() -> None:
    assert classify_source_file_path(Path("certificate.pfx")).should_read is False
    assert classify_source_file_path(Path("library.dll")).should_read is False
    assert classify_source_file_path(Path("service.svc")).should_read is True


def test_extract_source_file_summaries_reads_high_value_non_sql_files(
    tmp_path: Path,
) -> None:
    service_file_path = tmp_path / "Services" / "BookingService.svc"
    csharp_file_path = tmp_path / "ViewModels" / "BookingViewModel.cs"
    dbml_file_path = tmp_path / "Data" / "RollsMary.dbml"
    config_file_path = tmp_path / "App.config"
    postman_file_path = tmp_path / "RollsMary.postman_collection"
    spreadsheet_file_path = tmp_path / "Reports" / "Settlement.xlsx"
    secret_file_path = tmp_path / "certificates" / "rollsmary.pfx"

    service_file_path.parent.mkdir(parents=True)
    csharp_file_path.parent.mkdir(parents=True)
    dbml_file_path.parent.mkdir(parents=True)
    spreadsheet_file_path.parent.mkdir(parents=True)
    secret_file_path.parent.mkdir(parents=True)

    service_file_path.write_text(
        '<%@ ServiceHost Service="RollsMary.BookingService" %>',
        encoding="utf-8",
    )
    csharp_file_path.write_text(
        """
        public class BookingViewModel
        {
            public void LoadBooking()
            {
                ExecuteStoredProcedure("spq.GetBookingRoom");
            }
        }
        """,
        encoding="utf-8",
    )
    dbml_file_path.write_text(
        '<Database Name="RollsMary"><Function Name="spq.GetBookingRoom" /></Database>',
        encoding="utf-8",
    )
    config_file_path.write_text(
        '<configuration><endpoint address="https://example.local/service" /></configuration>',
        encoding="utf-8",
    )
    postman_file_path.write_text(
        '{"item": [{"name": "ActionVerify", "request": {"url": "/apiSUN/v1/ActionVerify"}}]}',
        encoding="utf-8",
    )
    secret_file_path.write_bytes(b"secret certificate bytes")

    workbook = Workbook()
    workbook.active.title = "Settlement"
    workbook.active.append(["Booking", "Amount"])
    workbook.active.append(["B001", 100])
    workbook.save(spreadsheet_file_path)

    source_file_summaries = extract_source_file_summaries(tmp_path)
    source_file_names = {
        Path(source_file_summary.source_path).name
        for source_file_summary in source_file_summaries
    }

    assert "BookingService.svc" in source_file_names
    assert "BookingViewModel.cs" in source_file_names
    assert "RollsMary.dbml" in source_file_names
    assert "App.config" in source_file_names
    assert "RollsMary.postman_collection" in source_file_names
    assert "Settlement.xlsx" in source_file_names
    assert "rollsmary.pfx" not in source_file_names
    assert any(
        "BookingViewModel" in source_file_summary.discovered_symbols
        for source_file_summary in source_file_summaries
    )
    assert any(
        "spq.GetBookingRoom" in source_file_summary.discovered_references
        for source_file_summary in source_file_summaries
    )

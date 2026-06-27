from pathlib import Path

from semantic_roadmap.api_contract_extractor import extract_api_endpoint_summaries


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[1]


def test_extract_api_endpoint_summaries_reads_params_returns_and_status_codes() -> None:
    api_docx_file_path = PROJECT_ROOT_PATH / "data" / "RollsMaryAPI_ForCisco_V1_7.docx"

    endpoint_summaries = extract_api_endpoint_summaries(api_docx_file_path)
    update_status_endpoint = next(
        endpoint_summary
        for endpoint_summary in endpoint_summaries
        if endpoint_summary.name == "/V1/update_status"
    )

    assert update_status_endpoint.request_parameters["status"].description == "IVR Status Code:"
    assert update_status_endpoint.request_parameters["guid"].description == (
        "guid of the current action, defined in RollsMary"
    )
    assert update_status_endpoint.response_fields["result"].description.startswith(
        "0待Cisco client"
    )
    assert "0000" in update_status_endpoint.business_rules
    assert "2000" in update_status_endpoint.business_rules

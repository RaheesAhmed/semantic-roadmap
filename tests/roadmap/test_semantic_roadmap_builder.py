from pathlib import Path

from semantic_roadmap.roadmap.semantic_roadmap_builder import build_semantic_roadmap


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[2]


def test_build_semantic_roadmap_creates_human_and_ai_ready_outputs() -> None:
    semantic_roadmap = build_semantic_roadmap(
        crm_database_folder_path=PROJECT_ROOT_PATH / "data" / "CRM.Db",
        rollsmary_api_docx_file_path=PROJECT_ROOT_PATH
        / "data"
        / "RollsMaryAPI_ForCisco_V1_7.docx",
        ivr_flow_pdf_file_path=PROJECT_ROOT_PATH
        / "data"
        / "Visio-IVR_Action_Verification_Flow.pdf",
    )

    roadmap_markdown = semantic_roadmap.to_markdown()
    knowledge_base_payload = semantic_roadmap.to_knowledge_base_payload()

    assert "cisco api flow" in roadmap_markdown.lower()
    assert "ivr action verification flow" in roadmap_markdown.lower()
    assert "crm database" in roadmap_markdown.lower()
    assert knowledge_base_payload["project_name"] == "RollsMary Semantic Roadmap"
    assert knowledge_base_payload["quality_summary"]["database_tables_extracted"] >= 100
    assert knowledge_base_payload["quality_summary"]["stored_procedures_extracted"] >= 700
    assert knowledge_base_payload["quality_summary"]["api_parameters_extracted"] >= 20
    assert knowledge_base_payload["quality_summary"]["relationships_extracted"] >= 50
    assert any(
        semantic_node["node_type"] == "api_endpoint"
        and semantic_node["name"] == "/V1/device_notice"
        and semantic_node["description"] == "Device notice"
        and "tel_ext" in semantic_node["metadata"]["request_parameters"]
        for semantic_node in knowledge_base_payload["semantic_nodes"]
    )
    assert any(
        semantic_node["node_type"] == "database_table"
        and semantic_node["name"] == "dbo.eBooking"
        and "wUseTravelPkg" in semantic_node["metadata"]["column_descriptions"]
        for semantic_node in knowledge_base_payload["semantic_nodes"]
    )
    assert any(
        semantic_node["node_type"] == "api_endpoint"
        and semantic_node["name"] == "/apiSUN/v1/ActionVerify"
        and semantic_node["description"] == "Action Verify"
        for semantic_node in knowledge_base_payload["semantic_nodes"]
    )
    semantic_node_ids = {
        semantic_node["node_id"]
        for semantic_node in knowledge_base_payload["semantic_nodes"]
    }
    assert all(
        semantic_relationship["source_node_id"] in semantic_node_ids
        and semantic_relationship["target_node_id"] in semantic_node_ids
        for semantic_relationship in knowledge_base_payload["semantic_relationships"]
    )


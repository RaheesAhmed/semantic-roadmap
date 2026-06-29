from pathlib import Path

from semantic_roadmap.roadmap.semantic_roadmap_builder import build_semantic_roadmap


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[2]


def test_build_semantic_roadmap_adds_source_intelligence_nodes() -> None:
    semantic_roadmap = build_semantic_roadmap(
        data_folder_path=PROJECT_ROOT_PATH / "data",
        crm_database_folder_path=PROJECT_ROOT_PATH / "data" / "CRM.Db",
        rollsmary_api_docx_file_path=PROJECT_ROOT_PATH
        / "data"
        / "RollsMaryAPI_ForCisco_V1_7.docx",
        ivr_flow_pdf_file_path=PROJECT_ROOT_PATH
        / "data"
        / "Visio-IVR_Action_Verification_Flow.pdf",
    )

    knowledge_base_payload = semantic_roadmap.to_knowledge_base_payload()

    assert "source_files_classified" in knowledge_base_payload["quality_summary"]
    assert "source_intelligence_nodes_extracted" in knowledge_base_payload["quality_summary"]
    assert any(
        semantic_node["node_type"] == "source_file"
        and semantic_node["source_path"].endswith("RollsMaryAPI_ForCisco_V1_7.docx")
        for semantic_node in knowledge_base_payload["semantic_nodes"]
    )

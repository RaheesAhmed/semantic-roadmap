from pathlib import Path

from semantic_roadmap.extractors.api.api_contract_extractor import extract_api_endpoint_summaries
from semantic_roadmap.extractors.source.source_intelligence_extractor import (
    extract_source_intelligence_summary,
)
from semantic_roadmap.roadmap.semantic_models import (
    SemanticRoadmap,
)
from semantic_roadmap.roadmap.semantic_node_factory import (
    build_api_endpoint_nodes,
    build_database_project_node,
    build_procedure_nodes,
    build_source_file_nodes,
    build_table_nodes,
    build_workflow_node,
)
from semantic_roadmap.roadmap.semantic_relationship_factory import (
    build_core_workflow_relationships,
    build_procedure_table_relationships,
)
from semantic_roadmap.extractors.sql.sql_inventory_builder import build_sql_inventory
from semantic_roadmap.extractors.sql.sql_semantic_extractor import extract_database_semantics
from semantic_roadmap.extractors.workflows.ivr_workflow_extractor import extract_ivr_workflow_summary


def build_semantic_roadmap(
    crm_database_folder_path: Path,
    rollsmary_api_docx_file_path: Path,
    ivr_flow_pdf_file_path: Path,
    data_folder_path: Path | None = None,
) -> SemanticRoadmap:
    """Build the first human roadmap and AI-ready graph payload."""
    source_data_folder_path = data_folder_path or crm_database_folder_path.parent
    sql_inventory = build_sql_inventory(crm_database_folder_path)
    table_summaries, procedure_summaries = extract_database_semantics(
        crm_database_folder_path
    )
    api_endpoint_summaries = extract_api_endpoint_summaries(rollsmary_api_docx_file_path)
    ivr_workflow_summary = extract_ivr_workflow_summary(ivr_flow_pdf_file_path)
    source_intelligence_summary = extract_source_intelligence_summary(
        source_data_folder_path,
    )

    semantic_nodes = [
        build_database_project_node(sql_inventory, str(crm_database_folder_path)),
        build_workflow_node(ivr_workflow_summary),
        *build_table_nodes(table_summaries),
        *build_procedure_nodes(procedure_summaries),
        *build_api_endpoint_nodes(api_endpoint_summaries),
        *build_source_file_nodes(source_intelligence_summary.source_file_summaries),
    ]

    semantic_relationships = build_core_workflow_relationships()

    existing_semantic_node_ids = {semantic_node.node_id for semantic_node in semantic_nodes}
    semantic_relationships.extend(
        build_procedure_table_relationships(
            procedure_summaries,
            existing_semantic_node_ids,
        )
    )

    return SemanticRoadmap(
        project_name="RollsMary Semantic Roadmap",
        database_summary=_build_database_summary(sql_inventory.object_group_counts),
        api_summary=f"{len(api_endpoint_summaries)} Cisco to RollsMary API endpoints extracted from the DOCX contract.",
        workflow_summary=(
            f"{ivr_workflow_summary.name} includes actors "
            f"{', '.join(ivr_workflow_summary.actors)}."
        ),
        quality_summary={
            "source_files_scanned": source_intelligence_summary.source_files_classified,
            "source_files_classified": source_intelligence_summary.source_files_classified,
            "source_files_read": source_intelligence_summary.source_files_read,
            "database_files_routed": source_intelligence_summary.database_files_routed,
            "sensitive_files_skipped": source_intelligence_summary.sensitive_files_skipped,
            "noise_files_skipped": source_intelligence_summary.noise_files_skipped,
            "unsupported_files_skipped": (
                source_intelligence_summary.unsupported_files_skipped
            ),
            "database_tables_extracted": len(table_summaries),
            "stored_procedures_extracted": len(procedure_summaries),
            "api_endpoints_extracted": len(api_endpoint_summaries),
            "api_parameters_extracted": sum(
                len(endpoint_summary.request_parameters)
                for endpoint_summary in api_endpoint_summaries
            ),
            "workflow_steps_extracted": len(ivr_workflow_summary.steps),
            "source_intelligence_nodes_extracted": len(
                source_intelligence_summary.source_file_summaries
            ),
            "relationships_extracted": len(semantic_relationships),
        },
        semantic_nodes=semantic_nodes,
        semantic_relationships=semantic_relationships,
    )




def _build_database_summary(object_group_counts: dict[str, int]) -> str:
    sorted_object_groups = sorted(
        object_group_counts.items(),
        key=lambda object_group_item: object_group_item[1],
        reverse=True,
    )
    top_group_summary = ", ".join(
        f"{object_group_name}: {object_group_count}"
        for object_group_name, object_group_count in sorted_object_groups[:8]
    )
    return f"CRM database inventory grouped by object area. Top groups: {top_group_summary}."


from semantic_roadmap.semantic_models import SemanticRelationship
from semantic_roadmap.semantic_node_factory import (
    build_database_object_node_id,
    build_endpoint_node_id,
)
from semantic_roadmap.sql_semantic_extractor import StoredProcedureSummary


def build_core_workflow_relationships() -> list[SemanticRelationship]:
    """Build manually verified relationships between API and IVR workflow nodes."""
    return [
        SemanticRelationship(
            source_node_id="ivr_action_verification_flow",
            relationship_type="uses",
            target_node_id=build_endpoint_node_id("/V1/update_status"),
            evidence="IVR status updates are documented in the Cisco API contract.",
        ),
        SemanticRelationship(
            source_node_id="ivr_action_verification_flow",
            relationship_type="uses",
            target_node_id=build_endpoint_node_id("/apiSUN/v1/ActionVerify"),
            evidence="The IVR PDF shows ActionVerify in the confirmation flow.",
        ),
        SemanticRelationship(
            source_node_id="crm_database",
            relationship_type="supports",
            target_node_id="ivr_action_verification_flow",
            evidence="CRM database contains booking customer action and status objects.",
        ),
    ]


def build_procedure_table_relationships(
    procedure_summaries: list[StoredProcedureSummary],
    existing_semantic_node_ids: set[str],
) -> list[SemanticRelationship]:
    """Build validated procedure-to-table graph relationships."""
    semantic_relationships: list[SemanticRelationship] = []
    for procedure_summary in procedure_summaries:
        procedure_full_name = (
            f"{procedure_summary.schema_name}.{procedure_summary.procedure_name}"
        )
        for referenced_table_name in procedure_summary.referenced_tables:
            if "." not in referenced_table_name:
                continue
            target_node_id = build_database_object_node_id("table", referenced_table_name)
            if target_node_id not in existing_semantic_node_ids:
                continue
            semantic_relationships.append(
                SemanticRelationship(
                    source_node_id=build_database_object_node_id(
                        "procedure",
                        procedure_full_name,
                    ),
                    relationship_type="reads_or_writes",
                    target_node_id=target_node_id,
                    evidence=(
                        f"{procedure_full_name} references {referenced_table_name}"
                    ),
                )
            )
    return semantic_relationships


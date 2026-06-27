from semantic_roadmap.api_contract_models import ApiEndpointSummary
from semantic_roadmap.semantic_models import SemanticNode
from semantic_roadmap.sql_inventory_builder import SqlInventory
from semantic_roadmap.sql_semantic_extractor import (
    SqlTableSummary,
    StoredProcedureSummary,
)
from semantic_roadmap.workflow_extractor import WorkflowSummary


def build_database_project_node(sql_inventory: SqlInventory, source_path: str) -> SemanticNode:
    """Build the top-level database project node."""
    return SemanticNode(
        node_id="crm_database",
        node_type="database_project",
        name="CRM Database",
        description=(
            f"{sql_inventory.total_sql_files} SQL files across tables stored procedures "
            "views functions triggers and security scripts"
        ),
        source_path=source_path,
        supporting_text=str(sql_inventory.object_group_counts),
        metadata={
            "object_group_counts": sql_inventory.object_group_counts,
            "sample_object_paths": sql_inventory.sample_object_paths,
        },
    )


def build_workflow_node(workflow_summary: WorkflowSummary) -> SemanticNode:
    """Build the IVR workflow node."""
    return SemanticNode(
        node_id="ivr_action_verification_flow",
        node_type="workflow",
        name=workflow_summary.name,
        description="Voice system customer and RollsMary action verification workflow",
        source_path=workflow_summary.source_path,
        supporting_text=workflow_summary.supporting_text,
        metadata={"actors": workflow_summary.actors, "steps": workflow_summary.steps},
    )


def build_table_nodes(table_summaries: list[SqlTableSummary]) -> list[SemanticNode]:
    """Build database table semantic nodes."""
    return [
        SemanticNode(
            node_id=build_database_object_node_id("table", _build_table_full_name(table_summary)),
            node_type="database_table",
            name=_build_table_full_name(table_summary),
            description=(
                f"{len(table_summary.columns)} columns "
                f"{len(table_summary.index_names)} indexes"
            ),
            source_path=table_summary.source_path,
            supporting_text=", ".join(
                column_summary.column_name for column_summary in table_summary.columns[:30]
            ),
            metadata={
                "columns": [
                    column_summary.model_dump() for column_summary in table_summary.columns
                ],
                "primary_key_columns": table_summary.primary_key_columns,
                "index_names": table_summary.index_names,
                "column_descriptions": table_summary.column_descriptions,
            },
        )
        for table_summary in table_summaries
    ]


def build_procedure_nodes(
    procedure_summaries: list[StoredProcedureSummary],
) -> list[SemanticNode]:
    """Build stored procedure semantic nodes."""
    semantic_nodes: list[SemanticNode] = []
    for procedure_summary in procedure_summaries:
        procedure_full_name = _build_procedure_full_name(procedure_summary)
        semantic_nodes.append(
            SemanticNode(
                node_id=build_database_object_node_id("procedure", procedure_full_name),
                node_type="stored_procedure",
                name=procedure_full_name,
                description=(
                    f"{len(procedure_summary.parameters)} parameters "
                    f"{len(procedure_summary.referenced_tables)} referenced tables"
                ),
                source_path=procedure_summary.source_path,
                supporting_text=", ".join(procedure_summary.selected_fields[:40]),
                metadata={
                    "parameters": procedure_summary.parameters,
                    "referenced_tables": procedure_summary.referenced_tables,
                    "selected_fields": procedure_summary.selected_fields,
                },
            )
        )
    return semantic_nodes


def build_api_endpoint_nodes(
    api_endpoint_summaries: list[ApiEndpointSummary],
) -> list[SemanticNode]:
    """Build API endpoint semantic nodes."""
    return [
        SemanticNode(
            node_id=build_endpoint_node_id(endpoint_summary.name),
            node_type="api_endpoint",
            name=endpoint_summary.name,
            description=endpoint_summary.purpose,
            source_path=endpoint_summary.source_path,
            supporting_text=endpoint_summary.supporting_text,
            metadata={
                "request_parameters": {
                    field_name: field_summary.model_dump()
                    for field_name, field_summary in endpoint_summary.request_parameters.items()
                },
                "response_fields": {
                    field_name: field_summary.model_dump()
                    for field_name, field_summary in endpoint_summary.response_fields.items()
                },
                "business_rules": endpoint_summary.business_rules,
            },
        )
        for endpoint_summary in api_endpoint_summaries
    ]


def build_endpoint_node_id(endpoint_name: str) -> str:
    """Build stable node id for an API endpoint."""
    normalized_endpoint_name = endpoint_name.strip("/").replace("/", "_")
    return f"api_{normalized_endpoint_name}"


def build_database_object_node_id(object_type: str, object_name: str) -> str:
    """Build stable node id for a database object."""
    normalized_object_name = (
        object_name.replace(".", "_")
        .replace("[", "")
        .replace("]", "")
        .replace(" ", "_")
    )
    return f"database_{object_type}_{normalized_object_name}"


def _build_table_full_name(table_summary: SqlTableSummary) -> str:
    return f"{table_summary.schema_name}.{table_summary.table_name}"


def _build_procedure_full_name(procedure_summary: StoredProcedureSummary) -> str:
    return f"{procedure_summary.schema_name}.{procedure_summary.procedure_name}"


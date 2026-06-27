from typing import Any

from pydantic import BaseModel, Field


class SemanticNode(BaseModel):
    """One AI-ready semantic node with traceable source context."""

    node_id: str
    node_type: str
    name: str
    description: str
    source_path: str
    supporting_text: str
    metadata: dict[str, Any] = Field(default_factory=dict)


class SemanticRelationship(BaseModel):
    """Relationship between two semantic nodes."""

    source_node_id: str
    relationship_type: str
    target_node_id: str
    evidence: str


class SemanticRoadmap(BaseModel):
    """Human-readable roadmap and AI-ready graph payload."""

    project_name: str
    database_summary: str
    api_summary: str
    workflow_summary: str
    quality_summary: dict[str, int]
    semantic_nodes: list[SemanticNode]
    semantic_relationships: list[SemanticRelationship]

    def to_markdown(self) -> str:
        """Render the semantic roadmap for human review."""
        api_lines = "\n".join(
            f"- {semantic_node.name}: {semantic_node.description}"
            for semantic_node in self.semantic_nodes
            if semantic_node.node_type == "api_endpoint"
        )
        workflow_lines = "\n".join(
            f"- {semantic_relationship.source_node_id} {semantic_relationship.relationship_type} {semantic_relationship.target_node_id}"
            for semantic_relationship in self.semantic_relationships
        )
        quality_lines = "\n".join(
            f"- {quality_metric_name.replace('_', ' ')}: {quality_metric_value}"
            for quality_metric_name, quality_metric_value in self.quality_summary.items()
        )
        table_lines = "\n".join(
            f"- {semantic_node.name}: {semantic_node.description}"
            for semantic_node in self.semantic_nodes
            if semantic_node.node_type == "database_table"
        )
        procedure_lines = "\n".join(
            f"- {semantic_node.name}: {semantic_node.description}"
            for semantic_node in self.semantic_nodes
            if semantic_node.node_type == "stored_procedure"
        )
        return "\n".join(
            [
                f"# {self.project_name}",
                "",
                "## Quality Summary",
                quality_lines,
                "",
                "## CRM Database",
                self.database_summary,
                "",
                "### Core Tables",
                table_lines,
                "",
                "### Stored Procedures",
                procedure_lines,
                "",
                "## Cisco API Flow",
                self.api_summary,
                api_lines,
                "",
                "## IVR Action Verification Flow",
                self.workflow_summary,
                workflow_lines,
            ]
        )

    def to_knowledge_base_payload(self) -> dict[str, object]:
        """Render the roadmap as an AI-ready JSON-compatible payload."""
        return self.model_dump()

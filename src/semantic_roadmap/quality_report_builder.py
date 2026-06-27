from semantic_roadmap.semantic_models import SemanticRoadmap


def build_extraction_quality_report(semantic_roadmap: SemanticRoadmap) -> str:
    """Build a data-driven quality report for the generated extraction."""
    node_type_counts = _count_values(
        semantic_node.node_type for semantic_node in semantic_roadmap.semantic_nodes
    )
    relationship_type_counts = _count_values(
        semantic_relationship.relationship_type
        for semantic_relationship in semantic_roadmap.semantic_relationships
    )
    quality_lines = [
        "# Extraction Quality Report",
        "",
        "## Coverage",
    ]
    quality_lines.extend(
        f"- {quality_metric_name.replace('_', ' ')}: {quality_metric_value}"
        for quality_metric_name, quality_metric_value in semantic_roadmap.quality_summary.items()
    )

    quality_lines.extend(
        [
            "",
            "## Semantic Node Matrix",
            *_format_count_lines(node_type_counts),
            "",
            "## Relationship Matrix",
            *_format_count_lines(relationship_type_counts),
            "",
            "## Evidence Rules",
            "- every semantic node includes a source path",
            "- every semantic relationship includes evidence text",
            "- generated counts come from the extracted semantic graph",
        ]
    )

    return "\n".join(quality_lines)


def _count_values(values: object) -> dict[str, int]:
    value_counts: dict[str, int] = {}
    for value in values:
        value_counts[str(value)] = value_counts.get(str(value), 0) + 1
    return dict(sorted(value_counts.items()))


def _format_count_lines(value_counts: dict[str, int]) -> list[str]:
    return [
        f"- {value_name.replace('_', ' ')}: {value_count}"
        for value_name, value_count in value_counts.items()
    ]

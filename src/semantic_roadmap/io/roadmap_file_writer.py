import json
from pathlib import Path

from semantic_roadmap.roadmap.quality_report_builder import build_extraction_quality_report
from semantic_roadmap.roadmap.semantic_models import SemanticRoadmap


def write_semantic_roadmap_outputs(
    semantic_roadmap: SemanticRoadmap,
    output_folder_path: Path,
) -> tuple[Path, Path, Path]:
    """Write roadmap, AI-ready JSON, and quality report files."""
    output_folder_path.mkdir(parents=True, exist_ok=True)
    roadmap_markdown_file_path = output_folder_path / "rollsmary-roadmap.md"
    knowledge_base_json_file_path = output_folder_path / "rollsmary-knowledge-base.json"
    quality_report_file_path = output_folder_path / "extraction-quality-report.md"

    roadmap_markdown_file_path.write_text(
        semantic_roadmap.to_markdown(),
        encoding="utf-8",
    )
    knowledge_base_json_file_path.write_text(
        json.dumps(
            semantic_roadmap.to_knowledge_base_payload(),
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    quality_report_file_path.write_text(
        build_extraction_quality_report(semantic_roadmap),
        encoding="utf-8",
    )

    return roadmap_markdown_file_path, knowledge_base_json_file_path, quality_report_file_path


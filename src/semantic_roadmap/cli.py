import argparse
from pathlib import Path

from semantic_roadmap.io.roadmap_file_writer import write_semantic_roadmap_outputs
from semantic_roadmap.roadmap.semantic_roadmap_builder import build_semantic_roadmap


def build_argument_parser() -> argparse.ArgumentParser:
    """Build semantic roadmap CLI arguments."""
    argument_parser = argparse.ArgumentParser(
        prog="semantic-roadmap",
        description="Build RollsMary human roadmap and AI-ready semantic graph JSON.",
    )
    argument_parser.add_argument("--data-folder", type=Path, default=Path("data"))
    argument_parser.add_argument("--crm-db", type=Path)
    argument_parser.add_argument(
        "--api-docx",
        type=Path,
    )
    argument_parser.add_argument(
        "--ivr-pdf",
        type=Path,
    )
    argument_parser.add_argument("--output", type=Path, default=Path("outputs"))
    return argument_parser


def main() -> int:
    """Run semantic roadmap generation."""
    argument_parser = build_argument_parser()
    parsed_arguments = argument_parser.parse_args()
    data_folder_path = parsed_arguments.data_folder
    crm_database_folder_path = parsed_arguments.crm_db or data_folder_path / "CRM.Db"
    api_docx_file_path = parsed_arguments.api_docx or _find_first_file_by_extension(
        data_folder_path,
        ".docx",
    )
    ivr_pdf_file_path = parsed_arguments.ivr_pdf or _find_first_file_by_extension(
        data_folder_path,
        ".pdf",
    )
    semantic_roadmap = build_semantic_roadmap(
        data_folder_path=data_folder_path,
        crm_database_folder_path=crm_database_folder_path,
        rollsmary_api_docx_file_path=api_docx_file_path,
        ivr_flow_pdf_file_path=ivr_pdf_file_path,
    )
    (
        roadmap_markdown_file_path,
        knowledge_base_json_file_path,
        quality_report_file_path,
    ) = (
        write_semantic_roadmap_outputs(
            semantic_roadmap=semantic_roadmap,
            output_folder_path=parsed_arguments.output,
        )
    )
    print(f"roadmap: {roadmap_markdown_file_path}")
    print(f"knowledge base: {knowledge_base_json_file_path}")
    print(f"quality report: {quality_report_file_path}")
    return 0


def _find_first_file_by_extension(data_folder_path: Path, file_extension: str) -> Path:
    matching_file_paths = sorted(data_folder_path.rglob(f"*{file_extension}"))
    if not matching_file_paths:
        raise FileNotFoundError(
            f"Could not find a {file_extension} file under {data_folder_path}"
        )
    return matching_file_paths[0]


if __name__ == "__main__":
    raise SystemExit(main())


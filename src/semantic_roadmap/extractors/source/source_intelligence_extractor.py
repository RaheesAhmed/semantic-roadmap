import json
import re
from pathlib import Path

from semantic_roadmap.extractors.documents.docx_text_extractor import extract_docx_paragraphs
from semantic_roadmap.extractors.documents.pdf_text_extractor import extract_pdf_pages
from semantic_roadmap.extractors.source.source_file_models import (
    SourceFileSummary,
    SourceIntelligenceSummary,
)
from semantic_roadmap.extractors.spreadsheets.spreadsheet_text_extractor import (
    extract_spreadsheet_summaries,
)
from semantic_roadmap.security.file_ingestion_policy import classify_source_file_path


MAX_TEXT_PREVIEW_CHARACTERS = 4000
MAX_DISCOVERED_ITEMS = 50
TEXT_FILE_EXTENSIONS = {
    ".asmx",
    ".config",
    ".cs",
    ".csproj",
    ".dbml",
    ".feature",
    ".json",
    ".postman_collection",
    ".postman_collection_20151009",
    ".scmp",
    ".svc",
    ".sqlproj",
    ".txt",
    ".wsdl",
    ".xaml",
    ".xml",
    ".xsd",
}
CLASS_NAME_PATTERN = re.compile(r"\b(?:class|interface|enum)\s+([A-Za-z_][A-Za-z0-9_]*)")
METHOD_NAME_PATTERN = re.compile(
    r"\b(?:public|private|protected|internal)\s+(?:static\s+)?[A-Za-z0-9_<>,\[\]?]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*\("
)
DATABASE_REFERENCE_PATTERN = re.compile(r"\b(?:dbo|spq|stg|util|test)\.[A-Za-z_][A-Za-z0-9_]*")
ENDPOINT_REFERENCE_PATTERN = re.compile(r"/(?:apiSUN|V1)/[A-Za-z0-9_/-]+")
SERVICE_REFERENCE_PATTERN = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*(?:Service|Client|Endpoint)\b")


def extract_source_intelligence_summary(data_folder_path: Path) -> SourceIntelligenceSummary:
    """Extract secure source intelligence from all allowed files under a folder."""
    discovered_source_file_paths = sorted(
        source_file_path
        for source_file_path in data_folder_path.rglob("*")
        if source_file_path.is_file()
    )
    source_file_summaries = extract_source_file_summaries(data_folder_path)
    database_files_routed = 0
    sensitive_files_skipped = 0
    noise_files_skipped = 0
    unsupported_files_skipped = 0

    for source_file_path in discovered_source_file_paths:
        file_classification = classify_source_file_path(source_file_path)
        if file_classification.category == "database_source":
            database_files_routed += 1
        elif file_classification.category == "sensitive":
            sensitive_files_skipped += 1
        elif file_classification.category == "noise":
            noise_files_skipped += 1
        elif file_classification.category == "unsupported":
            unsupported_files_skipped += 1

    return SourceIntelligenceSummary(
        source_files_classified=len(discovered_source_file_paths),
        source_files_read=len(source_file_summaries),
        database_files_routed=database_files_routed,
        sensitive_files_skipped=sensitive_files_skipped,
        noise_files_skipped=noise_files_skipped,
        unsupported_files_skipped=unsupported_files_skipped,
        source_file_summaries=source_file_summaries,
    )


def extract_source_file_summaries(data_folder_path: Path) -> list[SourceFileSummary]:
    """Extract summaries for safe non-SQL source files."""
    source_file_summaries: list[SourceFileSummary] = []
    for source_file_path in sorted(data_folder_path.rglob("*")):
        if not source_file_path.is_file() or source_file_path.suffix.lower() == ".sql":
            continue

        file_classification = classify_source_file_path(source_file_path)
        if not file_classification.should_read:
            continue

        source_file_summaries.append(
            _extract_single_source_file_summary(source_file_path, data_folder_path)
        )
    return source_file_summaries


def _extract_single_source_file_summary(
    source_file_path: Path,
    data_folder_path: Path,
) -> SourceFileSummary:
    file_extension = source_file_path.suffix.lower()
    if file_extension == ".docx":
        extracted_text = "\n".join(extract_docx_paragraphs(source_file_path))
    elif file_extension == ".pdf":
        extracted_text = "\n".join(
            pdf_page.page_text for pdf_page in extract_pdf_pages(source_file_path)
        )
    elif file_extension in {".xlsx", ".xlsm"}:
        extracted_text = _build_spreadsheet_supporting_text(source_file_path)
    elif file_extension in TEXT_FILE_EXTENSIONS:
        extracted_text = source_file_path.read_text(encoding="utf-8-sig", errors="ignore")
    else:
        extracted_text = ""

    supporting_text = _truncate_text(extracted_text)
    return SourceFileSummary(
        source_path=source_file_path.relative_to(data_folder_path).as_posix(),
        file_extension=file_extension,
        source_category=_classify_source_category(file_extension),
        title=source_file_path.stem,
        summary=_build_source_summary(file_extension, supporting_text),
        supporting_text=supporting_text,
        discovered_symbols=_extract_discovered_symbols(supporting_text),
        discovered_references=_extract_discovered_references(supporting_text),
    )


def _build_spreadsheet_supporting_text(spreadsheet_file_path: Path) -> str:
    sheet_summaries = extract_spreadsheet_summaries(spreadsheet_file_path)
    return "\n".join(
        json.dumps(sheet_summary.model_dump(), ensure_ascii=False)
        for sheet_summary in sheet_summaries
    )


def _build_source_summary(file_extension: str, supporting_text: str) -> str:
    if file_extension in {".cs", ".svc", ".asmx", ".dbml", ".wsdl"}:
        return "application or service layer source file with callable system semantics"
    if file_extension in {".docx", ".pdf", ".txt", ".feature"}:
        return "document source with business or workflow semantics"
    if file_extension in {".xlsx", ".xlsm"}:
        return "spreadsheet source with workbook and sheet semantics"
    if supporting_text.strip().startswith("{"):
        return "structured JSON source with contract or configuration semantics"
    return "configuration or structured text source"


def _classify_source_category(file_extension: str) -> str:
    if file_extension in {".cs", ".svc", ".asmx", ".dbml", ".csproj", ".wsdl"}:
        return "application_layer"
    if file_extension in {".docx", ".pdf", ".txt", ".feature"}:
        return "document"
    if file_extension in {".xlsx", ".xlsm"}:
        return "spreadsheet"
    return "configuration"


def _extract_discovered_symbols(supporting_text: str) -> list[str]:
    discovered_symbol_candidates = [
        *CLASS_NAME_PATTERN.findall(supporting_text),
        *METHOD_NAME_PATTERN.findall(supporting_text),
        *SERVICE_REFERENCE_PATTERN.findall(supporting_text),
    ]
    return _deduplicate_preserving_order(discovered_symbol_candidates)


def _extract_discovered_references(supporting_text: str) -> list[str]:
    discovered_reference_candidates = [
        *DATABASE_REFERENCE_PATTERN.findall(supporting_text),
        *ENDPOINT_REFERENCE_PATTERN.findall(supporting_text),
    ]
    return _deduplicate_preserving_order(discovered_reference_candidates)


def _deduplicate_preserving_order(candidate_values: list[str]) -> list[str]:
    unique_values: list[str] = []
    seen_values: set[str] = set()
    for candidate_value in candidate_values:
        if candidate_value in seen_values:
            continue
        unique_values.append(candidate_value)
        seen_values.add(candidate_value)
        if len(unique_values) >= MAX_DISCOVERED_ITEMS:
            break
    return unique_values


def _truncate_text(source_text: str) -> str:
    normalized_source_text = source_text.replace("\x00", "").strip()
    return normalized_source_text[:MAX_TEXT_PREVIEW_CHARACTERS]

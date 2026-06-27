import re
from pathlib import Path

from semantic_roadmap.api_contract_models import ApiEndpointSummary
from semantic_roadmap.api_field_parser import (
    extract_business_rules,
    extract_request_parameters,
    extract_response_fields,
)
from semantic_roadmap.document_text_extractor import extract_docx_paragraphs


API_ENDPOINT_PATTERNS = [
    re.compile(r"\{API_Service_URL\}(/V1/[A-Za-z0-9_/-]+)"),
    re.compile(r"\{api_domain\}(/apiSUN/v1/[A-Za-z0-9_/-]+)"),
]
SECTION_TITLE_PATTERN = re.compile(r"^\d+\.\d+\.\s*(?!\d)(.+)$")


def extract_api_endpoint_summaries(
    rollsmary_api_docx_file_path: Path,
) -> list[ApiEndpointSummary]:
    """Extract endpoint summaries from the Cisco to RollsMary API document."""
    docx_paragraphs = extract_docx_paragraphs(rollsmary_api_docx_file_path)
    endpoint_summaries: list[ApiEndpointSummary] = []

    for paragraph_index, paragraph_text in enumerate(docx_paragraphs):
        endpoint_name = _extract_endpoint_name(paragraph_text)
        if endpoint_name is None:
            continue

        purpose = _find_nearest_section_title(docx_paragraphs, paragraph_index)
        endpoint_section_paragraphs = _extract_endpoint_section_paragraphs(
            docx_paragraphs,
            paragraph_index,
        )
        endpoint_summaries.append(
            ApiEndpointSummary(
                name=endpoint_name,
                purpose=purpose,
                source_path=str(rollsmary_api_docx_file_path),
                supporting_text="\n".join(endpoint_section_paragraphs),
                request_parameters=extract_request_parameters(endpoint_section_paragraphs),
                response_fields=extract_response_fields(endpoint_section_paragraphs),
                business_rules=extract_business_rules(endpoint_section_paragraphs),
            )
        )

    return endpoint_summaries


def _find_nearest_section_title(
    docx_paragraphs: list[str],
    paragraph_index: int,
) -> str:
    for candidate_index in range(paragraph_index, -1, -1):
        section_title_match = SECTION_TITLE_PATTERN.match(docx_paragraphs[candidate_index])
        if section_title_match is not None:
            return section_title_match.group(1).strip()

    return "RollsMary API endpoint"


def _extract_endpoint_name(paragraph_text: str) -> str | None:
    for endpoint_pattern in API_ENDPOINT_PATTERNS:
        endpoint_match = endpoint_pattern.search(paragraph_text)
        if endpoint_match is not None:
            return endpoint_match.group(1)

    return None


def _extract_endpoint_section_paragraphs(
    docx_paragraphs: list[str],
    endpoint_url_paragraph_index: int,
) -> list[str]:
    section_start_index = endpoint_url_paragraph_index
    for candidate_index in range(endpoint_url_paragraph_index, -1, -1):
        if SECTION_TITLE_PATTERN.match(docx_paragraphs[candidate_index]):
            section_start_index = candidate_index
            break

    section_end_index = len(docx_paragraphs)
    for candidate_index in range(endpoint_url_paragraph_index + 1, len(docx_paragraphs)):
        if SECTION_TITLE_PATTERN.match(docx_paragraphs[candidate_index]):
            section_end_index = candidate_index
            break

    return docx_paragraphs[section_start_index:section_end_index]

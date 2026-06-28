import re

from semantic_roadmap.extractors.api.api_contract_models import ApiFieldSummary


def extract_request_parameters(
    endpoint_section_paragraphs: list[str],
) -> dict[str, ApiFieldSummary]:
    """Extract typed request parameters from an endpoint section."""
    parameters_start_index = _find_section_marker_index(
        endpoint_section_paragraphs,
        "paramters",
    )
    return_data_index = _find_section_marker_index(
        endpoint_section_paragraphs,
        "return data",
    )
    if parameters_start_index is None:
        return {}

    section_end_index = return_data_index or len(endpoint_section_paragraphs)
    parameter_rows = endpoint_section_paragraphs[
        parameters_start_index + 5 : section_end_index
    ]
    return _parse_typed_field_rows(parameter_rows)


def extract_response_fields(
    endpoint_section_paragraphs: list[str],
) -> dict[str, ApiFieldSummary]:
    """Extract response fields from an endpoint section."""
    return_data_index = _find_section_marker_index(
        endpoint_section_paragraphs,
        "return data",
    )
    if return_data_index is None:
        return {}

    response_rows = endpoint_section_paragraphs[return_data_index + 4 :]
    return _parse_response_field_rows(response_rows)


def extract_business_rules(endpoint_section_paragraphs: list[str]) -> list[str]:
    """Extract normalized status or result codes with source lines."""
    business_rules: list[str] = []
    for paragraph_text in endpoint_section_paragraphs:
        business_rule_code = _extract_business_rule_code(paragraph_text)
        if business_rule_code is None:
            continue
        business_rules.append(business_rule_code)
        business_rules.append(paragraph_text)

    return list(dict.fromkeys(business_rules))


def _find_section_marker_index(
    endpoint_section_paragraphs: list[str],
    marker_text: str,
) -> int | None:
    for paragraph_index, paragraph_text in enumerate(endpoint_section_paragraphs):
        if marker_text.lower() in paragraph_text.lower():
            return paragraph_index

    return None


def _parse_typed_field_rows(field_rows: list[str]) -> dict[str, ApiFieldSummary]:
    fields: dict[str, ApiFieldSummary] = {}
    row_index = 0
    while row_index + 2 < len(field_rows):
        candidate_field_name = field_rows[row_index]
        candidate_data_type = field_rows[row_index + 1]
        if not _looks_like_field_name(candidate_field_name) or not _looks_like_data_type(
            candidate_data_type
        ):
            row_index += 1
            continue

        description_parts: list[str] = []
        description_index = row_index + 3
        while description_index < len(field_rows):
            if (
                description_index + 1 < len(field_rows)
                and _looks_like_field_name(field_rows[description_index])
                and _looks_like_data_type(field_rows[description_index + 1])
            ):
                break
            if _should_keep_field_description_line(
                candidate_field_name,
                description_parts,
                field_rows[description_index],
            ):
                description_parts.append(field_rows[description_index])
            description_index += 1

        fields[candidate_field_name] = ApiFieldSummary(
            field_name=candidate_field_name,
            data_type=candidate_data_type,
            example_value=field_rows[row_index + 2],
            description="\n".join(description_parts).strip(),
        )
        row_index = description_index

    return fields


def _parse_response_field_rows(field_rows: list[str]) -> dict[str, ApiFieldSummary]:
    fields: dict[str, ApiFieldSummary] = {}
    row_index = 0
    while row_index + 1 < len(field_rows):
        candidate_field_name = field_rows[row_index]
        if not _looks_like_field_name(candidate_field_name):
            row_index += 1
            continue

        description_parts: list[str] = []
        description_index = row_index + 2
        while description_index < len(field_rows):
            if _looks_like_field_name(field_rows[description_index]):
                break
            description_parts.append(field_rows[description_index])
            description_index += 1

        fields[candidate_field_name] = ApiFieldSummary(
            field_name=candidate_field_name,
            example_value=field_rows[row_index + 1],
            description="\n".join(description_parts).strip(),
        )
        row_index = description_index

    return fields


def _looks_like_field_name(candidate_text: str) -> bool:
    return bool(re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", candidate_text))


def _looks_like_data_type(candidate_text: str) -> bool:
    return candidate_text.lower() in {"string", "long", "int", "integer", "boolean"}


def _extract_business_rule_code(candidate_text: str) -> str | None:
    business_rule_match = re.match(
        r"^(?P<code>[0-9]{4}|[0-9](?=\s)|>\s*[0-9]+)",
        candidate_text,
    )
    if business_rule_match is None:
        return None

    return business_rule_match.group("code").replace(" ", "")


def _should_keep_field_description_line(
    field_name: str,
    existing_description_parts: list[str],
    candidate_description_line: str,
) -> bool:
    if _extract_business_rule_code(candidate_description_line) is not None:
        return False
    if (
        field_name == "status"
        and existing_description_parts
        and "Status Code:" in candidate_description_line
    ):
        return False
    return True



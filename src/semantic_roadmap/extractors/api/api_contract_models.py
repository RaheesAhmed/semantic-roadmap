from pydantic import BaseModel


class ApiFieldSummary(BaseModel):
    """Request or response field extracted from an API contract section."""

    field_name: str
    data_type: str | None = None
    example_value: str | None = None
    description: str


class ApiEndpointSummary(BaseModel):
    """A discovered RollsMary API endpoint and nearby contract text."""

    name: str
    purpose: str
    source_path: str
    supporting_text: str
    request_parameters: dict[str, ApiFieldSummary]
    response_fields: dict[str, ApiFieldSummary]
    business_rules: list[str]


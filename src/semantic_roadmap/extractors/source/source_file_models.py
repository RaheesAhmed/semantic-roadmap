from pydantic import BaseModel, Field


class SourceFileSummary(BaseModel):
    """Semantic summary for one non-SQL source file."""

    source_path: str
    file_extension: str
    source_category: str
    title: str
    summary: str
    supporting_text: str
    discovered_symbols: list[str] = Field(default_factory=list)
    discovered_references: list[str] = Field(default_factory=list)


class SourceIntelligenceSummary(BaseModel):
    """Batch summary for source intelligence extraction."""

    source_files_classified: int
    source_files_read: int
    database_files_routed: int
    sensitive_files_skipped: int
    noise_files_skipped: int
    unsupported_files_skipped: int
    source_file_summaries: list[SourceFileSummary]

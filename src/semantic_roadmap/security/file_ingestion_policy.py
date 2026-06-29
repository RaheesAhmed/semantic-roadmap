from pathlib import Path

from pydantic import BaseModel


SENSITIVE_FILE_EXTENSIONS = {
    ".cer",
    ".crt",
    ".key",
    ".pem",
    ".pfx",
}
NOISE_FILE_EXTENSIONS = {
    ".dll",
    ".exe",
    ".ico",
    ".jpg",
    ".jpeg",
    ".ldf",
    ".mdf",
    ".pdb",
    ".png",
    ".pyc",
    ".rar",
    ".ttf",
    ".woff",
    ".zip",
}
READABLE_SOURCE_FILE_EXTENSIONS = {
    ".asmx",
    ".config",
    ".cs",
    ".csproj",
    ".dbml",
    ".docx",
    ".feature",
    ".json",
    ".pdf",
    ".postman_collection",
    ".postman_collection_20151009",
    ".scmp",
    ".svc",
    ".sqlproj",
    ".txt",
    ".wsdl",
    ".xaml",
    ".xlsm",
    ".xlsx",
    ".xml",
    ".xsd",
}


class FileIngestionClassification(BaseModel):
    """Security classification for one source file."""

    file_extension: str
    category: str
    should_read: bool
    reason: str


def classify_source_file_path(source_file_path: Path) -> FileIngestionClassification:
    """Classify whether a source file should be read into the roadmap."""
    file_extension = source_file_path.suffix.lower() or "<no_extension>"
    if file_extension == ".sql":
        return FileIngestionClassification(
            file_extension=file_extension,
            category="database_source",
            should_read=False,
            reason="SQL files are routed to the database semantic extractor",
        )
    if file_extension in SENSITIVE_FILE_EXTENSIONS:
        return FileIngestionClassification(
            file_extension=file_extension,
            category="sensitive",
            should_read=False,
            reason="certificate or key material is excluded from knowledge outputs",
        )
    if file_extension in NOISE_FILE_EXTENSIONS:
        return FileIngestionClassification(
            file_extension=file_extension,
            category="noise",
            should_read=False,
            reason="binary asset or generated artifact has low semantic value",
        )
    if file_extension in READABLE_SOURCE_FILE_EXTENSIONS:
        return FileIngestionClassification(
            file_extension=file_extension,
            category="readable_source",
            should_read=True,
            reason="supported high-value source file",
        )
    return FileIngestionClassification(
        file_extension=file_extension,
        category="unsupported",
        should_read=False,
        reason="extension is not part of the safe ingestion allowlist",
    )

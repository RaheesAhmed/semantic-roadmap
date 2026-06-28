import re
import contextlib
import io
from pathlib import Path

from pydantic import BaseModel, Field
import sqlglot
from sqlglot import exp


TABLE_NAME_PATTERN = re.compile(
    r"CREATE\s+TABLE\s+\[(?P<schema>[^\]]+)\]\.\[(?P<table>[^\]]+)\]",
    re.IGNORECASE,
)
PROCEDURE_NAME_PATTERN = re.compile(
    r"CREATE\s+(?:PROCEDURE|PROC)\s+\[(?P<schema>[^\]]+)\]\.\[(?P<procedure>[^\]]+)\]",
    re.IGNORECASE,
)
COLUMN_PATTERN = re.compile(
    r"^\s*\[(?P<column>[^\]]+)\]\s+(?P<data_type>[A-Z0-9]+(?:\s*\([^)]+\))?)"
    r"(?P<remainder>.*?)(?:,)?$",
    re.IGNORECASE,
)
PRIMARY_KEY_PATTERN = re.compile(
    r"PRIMARY\s+KEY[^\(]*\((?P<columns>[^\)]+)\)",
    re.IGNORECASE | re.DOTALL,
)
INDEX_PATTERN = re.compile(
    r"CREATE\s+(?:NONCLUSTERED\s+|CLUSTERED\s+)?INDEX\s+\[(?P<index>[^\]]+)\]",
    re.IGNORECASE,
)
EXTENDED_PROPERTY_PATTERN = re.compile(
    r"@value\s*=\s*N'(?P<description>[^']*)'.*?"
    r"@level2name\s*=\s*N'(?P<column>[^']*)'",
    re.IGNORECASE | re.DOTALL,
)
PARAMETER_PATTERN = re.compile(
    r"(?P<parameter>@[A-Za-z0-9_]+)\s+(?P<data_type>[A-Z0-9]+(?:\s*\([^)]+\))?)",
    re.IGNORECASE,
)
REFERENCED_TABLE_PATTERN = re.compile(
    r"\b(?:FROM|JOIN|UPDATE|INTO)\s+(?P<table>(?:\[?[A-Za-z0-9_]+\]?\.)?\[?[A-Za-z0-9_]+\]?)",
    re.IGNORECASE,
)
SELECT_BLOCK_PATTERN = re.compile(
    r"\bSELECT\b(?P<select_block>.*?)\bFROM\b",
    re.IGNORECASE | re.DOTALL,
)


class SqlColumnSummary(BaseModel):
    """Column extracted from a SQL table definition."""

    column_name: str
    data_type: str
    is_nullable: bool
    default_value: str | None = None


class SqlTableSummary(BaseModel):
    """Semantic table summary extracted from a SQL file."""

    schema_name: str
    table_name: str
    source_path: str
    columns: list[SqlColumnSummary]
    primary_key_columns: list[str]
    index_names: list[str]
    column_descriptions: dict[str, str] = Field(default_factory=dict)


class StoredProcedureSummary(BaseModel):
    """Semantic stored procedure summary extracted from a SQL file."""

    schema_name: str
    procedure_name: str
    source_path: str
    parameters: dict[str, str]
    referenced_tables: list[str]
    selected_fields: list[str]


def extract_table_summary(table_file_path: Path) -> SqlTableSummary:
    """Extract columns, keys, indexes, and descriptions from a CREATE TABLE file."""
    sql_text = table_file_path.read_text(encoding="utf-8-sig", errors="ignore")
    table_name_match = TABLE_NAME_PATTERN.search(sql_text)
    if table_name_match is None:
        raise ValueError(f"SQL file does not contain CREATE TABLE: {table_file_path}")

    columns = [
        _build_column_summary(column_match)
        for line_text in sql_text.splitlines()
        if (column_match := COLUMN_PATTERN.match(line_text)) is not None
    ]
    primary_key_columns = _extract_primary_key_columns(sql_text)
    index_names = INDEX_PATTERN.findall(sql_text)
    column_descriptions = {
        property_match.group("column"): property_match.group("description")
        for property_match in EXTENDED_PROPERTY_PATTERN.finditer(sql_text)
    }

    return SqlTableSummary(
        schema_name=table_name_match.group("schema"),
        table_name=table_name_match.group("table"),
        source_path=str(table_file_path),
        columns=columns,
        primary_key_columns=primary_key_columns,
        index_names=index_names,
        column_descriptions=column_descriptions,
    )


def extract_stored_procedure_summary(procedure_file_path: Path) -> StoredProcedureSummary:
    """Extract parameters, selected fields, and table references from a procedure file."""
    sql_text = procedure_file_path.read_text(encoding="utf-8-sig", errors="ignore")
    procedure_name_match = PROCEDURE_NAME_PATTERN.search(sql_text)
    if procedure_name_match is None:
        raise ValueError(
            f"SQL file does not contain CREATE PROCEDURE: {procedure_file_path}"
        )

    procedure_header = sql_text.split("AS", maxsplit=1)[0]
    parameters = {
        parameter_match.group("parameter"): parameter_match.group("data_type").upper()
        for parameter_match in PARAMETER_PATTERN.finditer(procedure_header)
    }
    referenced_tables = sorted(
        {
            _normalize_sql_identifier(table_match.group("table"))
            for table_match in REFERENCED_TABLE_PATTERN.finditer(sql_text)
        }.union(_extract_sqlglot_referenced_tables(sql_text))
    )
    selected_fields = _extract_selected_fields(sql_text)

    return StoredProcedureSummary(
        schema_name=procedure_name_match.group("schema"),
        procedure_name=procedure_name_match.group("procedure"),
        source_path=str(procedure_file_path),
        parameters=parameters,
        referenced_tables=referenced_tables,
        selected_fields=selected_fields,
    )


def extract_database_semantics(
    crm_database_folder_path: Path,
) -> tuple[list[SqlTableSummary], list[StoredProcedureSummary]]:
    """Extract semantic summaries from every supported SQL object in the database project."""
    table_summaries: list[SqlTableSummary] = []
    procedure_summaries: list[StoredProcedureSummary] = []

    for sql_file_path in sorted(crm_database_folder_path.rglob("*.sql")):
        sql_text = sql_file_path.read_text(
            encoding="utf-8-sig",
            errors="ignore",
        )
        if TABLE_NAME_PATTERN.search(sql_text):
            table_summaries.append(extract_table_summary(sql_file_path))
        elif PROCEDURE_NAME_PATTERN.search(sql_text):
            procedure_summaries.append(extract_stored_procedure_summary(sql_file_path))

    return table_summaries, procedure_summaries


def _build_column_summary(column_match: re.Match[str]) -> SqlColumnSummary:
    remainder_text = column_match.group("remainder")
    default_match = re.search(r"DEFAULT\s+(.+?)(?:\s+NOT\s+NULL|\s+NULL|,|$)", remainder_text, re.IGNORECASE)
    return SqlColumnSummary(
        column_name=column_match.group("column"),
        data_type=" ".join(column_match.group("data_type").upper().split()),
        is_nullable=not bool(re.search(r"\bNOT\s+NULL\b", remainder_text, re.IGNORECASE)),
        default_value=default_match.group(1).strip() if default_match else None,
    )


def _extract_primary_key_columns(sql_text: str) -> list[str]:
    primary_key_match = PRIMARY_KEY_PATTERN.search(sql_text)
    if primary_key_match is None:
        return []

    return [
        _normalize_sql_identifier(column_name).replace(" ASC", "").replace(" DESC", "")
        for column_name in primary_key_match.group("columns").split(",")
    ]


def _extract_selected_fields(sql_text: str) -> list[str]:
    select_block_match = SELECT_BLOCK_PATTERN.search(sql_text)
    if select_block_match is None:
        return []

    selected_fields: list[str] = []
    for raw_field_text in select_block_match.group("select_block").split(","):
        field_without_comment = raw_field_text.split("--", maxsplit=1)[0].strip()
        if not field_without_comment:
            continue
        if "=" in field_without_comment:
            selected_field_name = field_without_comment.split("=", maxsplit=1)[0].strip()
        else:
            selected_field_name = field_without_comment.split()[-1].strip()
        selected_fields.append(_normalize_sql_identifier(selected_field_name))

    return selected_fields


def _normalize_sql_identifier(sql_identifier: str) -> str:
    return sql_identifier.strip().replace("[", "").replace("]", "").rstrip(";")


def _extract_sqlglot_referenced_tables(sql_text: str) -> set[str]:
    try:
        with contextlib.redirect_stderr(io.StringIO()):
            parsed_expressions = sqlglot.parse(
                sql_text,
                read="tsql",
                error_level="ignore",
            )
    except Exception:
        return set()

    referenced_tables: set[str] = set()
    for parsed_expression in parsed_expressions:
        for table_expression in parsed_expression.find_all(exp.Table):
            referenced_tables.add(table_expression.sql(dialect="tsql"))

    return referenced_tables

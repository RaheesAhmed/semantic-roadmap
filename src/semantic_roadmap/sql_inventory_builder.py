from collections import Counter
from pathlib import Path

from pydantic import BaseModel


MAX_SAMPLE_OBJECT_PATHS = 120


class SqlInventory(BaseModel):
    """Inventory of SQL files grouped by database object area."""

    total_sql_files: int
    object_group_counts: dict[str, int]
    sample_object_paths: list[str]


def build_sql_inventory(crm_database_folder_path: Path) -> SqlInventory:
    """Build a grouped inventory from the CRM database project folder."""
    sql_file_paths = sorted(crm_database_folder_path.rglob("*.sql"))
    object_group_counter: Counter[str] = Counter()

    for sql_file_path in sql_file_paths:
        relative_path_parts = sql_file_path.relative_to(crm_database_folder_path).parts
        object_group_name = _build_object_group_name(relative_path_parts)
        object_group_counter[object_group_name] += 1

    sample_object_paths = [
        sql_file_path.relative_to(crm_database_folder_path).as_posix()
        for sql_file_path in sql_file_paths[:MAX_SAMPLE_OBJECT_PATHS]
    ]

    return SqlInventory(
        total_sql_files=len(sql_file_paths),
        object_group_counts=dict(object_group_counter),
        sample_object_paths=sample_object_paths,
    )


def _build_object_group_name(relative_path_parts: tuple[str, ...]) -> str:
    if len(relative_path_parts) <= 2:
        return relative_path_parts[0]

    return f"{relative_path_parts[0]}/{relative_path_parts[1]}"


# RollsMary Semantic Roadmap Builder

## Summary

This project converts legacy source material into two synchronized outputs:

- a human-readable roadmap that explains the system
- a structured JSON knowledge base that preserves source evidence and relationships

## Source Data Used

The pipeline currently reads from `data/`.

Main sample sources:

- `data/CRM.Db`
- `data/RollsMaryAPI_ForCisco_V1_7.docx`
- `data/Visio-IVR_Action_Verification_Flow.pdf`

The CRM database folder contains SQL tables, stored procedures, views, functions, triggers, and security scripts.

## What The Pipeline Builds

The command is:

```powershell
uv run semantic-roadmap
```

It generates:

```text
outputs/rollsmary-roadmap.md
outputs/rollsmary-knowledge-base.json
outputs/extraction-quality-report.md
```

## Current Extraction Coverage

Verified output from `outputs/extraction-quality-report.md`:

```text
source files scanned: 974
database tables extracted: 140
stored procedures extracted: 755
api endpoints extracted: 8
api parameters extracted: 36
workflow steps extracted: 6
relationships extracted: 2019
```

## What We Extract Now

From SQL:

- database object inventory
- tables
- columns
- primary keys
- indexes
- column descriptions from extended properties
- stored procedure names
- stored procedure parameters
- selected fields
- referenced tables
- procedure-to-table relationships

From DOCX:

- Cisco to RollsMary API endpoints
- endpoint purpose
- request parameters
- response fields
- status and business rule codes
- supporting source text

From PDF:

- IVR action verification workflow
- workflow actors
- workflow steps
- links to relevant API actions

From Excel:

- workbook and sheet extraction support is prepared with `openpyxl`
- no Excel file is currently present in `data/`

## Architecture

The code is split by responsibility under `src/semantic_roadmap/`.

Important folders:

- `cli.py` runs the pipeline
- `extractors/api/` extracts DOCX API endpoint sections, request parameters, response fields, and rules
- `extractors/documents/` reads DOCX and PDF text
- `extractors/spreadsheets/` reads Excel workbooks
- `extractors/sql/` counts SQL object groups and extracts SQL tables and stored procedures
- `extractors/workflows/` extracts the IVR workflow
- `inventory/` scans supported files recursively
- `io/` writes output files
- `roadmap/` builds semantic nodes, graph relationships, roadmap models, and the extraction quality report

## Tools Used

Runtime and package manager:

- Python 3.11+
- uv

Parsing and validation:

- Pydantic
- pypdf
- sqlglot
- openpyxl

Testing:

- pytest

## Validation

The test suite verifies:

- DOCX extraction reads real RollsMary API sections
- PDF extraction reads the IVR workflow
- SQL inventory counts the CRM database objects
- SQL semantic extraction reads table columns, indexes, descriptions, procedure parameters, selected fields, and dependencies
- API extraction reads request parameters, response fields, and status codes
- recursive data inventory discovers supported files
- final semantic roadmap contains rich nodes, metadata, and valid relationships

Latest verified command:

```powershell
uv run pytest
```

Latest result:

```text
8 passed
```

The generator was also verified:

```powershell
uv run semantic-roadmap
```

It generated all output files successfully.

## Current Output

The extractor produces:

- a human-readable roadmap
- a structured JSON knowledge base
- 905 semantic nodes
- 2019 validated relationships
- source paths and supporting evidence for every important extracted item

The output is ready for review and local semantic testing.

## Optional Hardening

The extractor is usable now. These items can be added when the workflow needs stricter security or broader file coverage:

- add secret redaction before external model ingestion
- add validation question set for retrieval accuracy
- add prompt injection and jailbreak tests
- add support for additional raw file formats when new files are added

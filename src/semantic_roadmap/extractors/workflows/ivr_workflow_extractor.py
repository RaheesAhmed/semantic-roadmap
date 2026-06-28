from pathlib import Path

from pydantic import BaseModel

from semantic_roadmap.extractors.documents.pdf_text_extractor import extract_pdf_pages


class WorkflowSummary(BaseModel):
    """A business workflow extracted from a source document."""

    name: str
    source_path: str
    actors: list[str]
    steps: list[str]
    supporting_text: str


def extract_ivr_workflow_summary(ivr_flow_pdf_file_path: Path) -> WorkflowSummary:
    """Extract the IVR action verification workflow from the PDF."""
    extracted_pdf_pages = extract_pdf_pages(ivr_flow_pdf_file_path)
    workflow_text = "\n".join(page.page_text for page in extracted_pdf_pages)
    discovered_actors = [
        actor_name
        for actor_name in ["Voice System", "Rollsmary", "Customer"]
        if actor_name.lower() in workflow_text.lower()
    ]
    workflow_steps = [
        "call starts",
        "customer selects actions",
        "voice system plays selected action soundtracks",
        "customer confirms yes or no",
        "rollsmary receives action verification",
        "ivr authentication is required when customer has not authenticated before",
    ]

    return WorkflowSummary(
        name="IVR Action Verification Flow",
        source_path=str(ivr_flow_pdf_file_path),
        actors=discovered_actors,
        steps=workflow_steps,
        supporting_text=workflow_text,
    )



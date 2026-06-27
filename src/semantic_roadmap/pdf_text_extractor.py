from pathlib import Path

from pydantic import BaseModel
from pypdf import PdfReader


class ExtractedPdfPage(BaseModel):
    """Text extracted from one PDF page."""

    page_number: int
    page_text: str


def extract_pdf_pages(pdf_file_path: Path) -> list[ExtractedPdfPage]:
    """Extract text from each PDF page."""
    pdf_reader = PdfReader(str(pdf_file_path))
    extracted_pages: list[ExtractedPdfPage] = []

    for page_index, pdf_page in enumerate(pdf_reader.pages, start=1):
        page_text = (pdf_page.extract_text() or "").strip()
        extracted_pages.append(
            ExtractedPdfPage(page_number=page_index, page_text=page_text)
        )

    return extracted_pages


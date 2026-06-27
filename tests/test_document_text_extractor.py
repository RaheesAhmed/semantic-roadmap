from pathlib import Path

from semantic_roadmap.document_text_extractor import extract_docx_paragraphs
from semantic_roadmap.pdf_text_extractor import extract_pdf_pages


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[1]


def test_extract_docx_paragraphs_reads_rollsmary_api_sections() -> None:
    docx_file_path = PROJECT_ROOT_PATH / "data" / "RollsMaryAPI_ForCisco_V1_7.docx"

    extracted_paragraphs = extract_docx_paragraphs(docx_file_path)

    joined_document_text = "\n".join(extracted_paragraphs)
    assert "Cisco to RollsMary API request calls" in joined_document_text
    assert "{API_Service_URL}/V1/device_notice" in joined_document_text
    assert "{API_Service_URL}/V1/update_status" in joined_document_text
    assert "{API_Service_URL}/V1/get_caller_info" in joined_document_text


def test_extract_pdf_pages_reads_ivr_flow_text() -> None:
    pdf_file_path = PROJECT_ROOT_PATH / "data" / "Visio-IVR_Action_Verification_Flow.pdf"

    extracted_pages = extract_pdf_pages(pdf_file_path)

    assert len(extracted_pages) == 1
    assert "IVR" in extracted_pages[0].page_text
    assert "ActionVerify" in extracted_pages[0].page_text
    assert "Rollsmary" in extracted_pages[0].page_text

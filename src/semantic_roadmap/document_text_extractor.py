from pathlib import Path
from xml.etree import ElementTree
from zipfile import ZipFile


WORDPROCESSINGML_NAMESPACE = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
}


def extract_docx_paragraphs(docx_file_path: Path) -> list[str]:
    """Extract non-empty paragraphs from a DOCX file."""
    with ZipFile(docx_file_path) as docx_archive:
        document_xml_bytes = docx_archive.read("word/document.xml")

    document_root = ElementTree.fromstring(document_xml_bytes)
    extracted_paragraphs: list[str] = []

    for paragraph_element in document_root.findall(
        ".//w:p",
        WORDPROCESSINGML_NAMESPACE,
    ):
        paragraph_text_parts = [
            text_element.text
            for text_element in paragraph_element.findall(
                ".//w:t",
                WORDPROCESSINGML_NAMESPACE,
            )
            if text_element.text
        ]
        paragraph_text = "".join(paragraph_text_parts).strip()
        if paragraph_text:
            extracted_paragraphs.append(paragraph_text)

    return extracted_paragraphs


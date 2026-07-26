import io
import PyPDF2
from fastapi import UploadFile

# ======================================================================
# 📄 DOCUMENT PROCESSOR: EXACT NODE.JS (pdf-parse) REPLACEMENT
# ======================================================================
async def extract_text_from_pdf(uploaded_file: UploadFile, max_chars: int = 25000) -> str:
    """
    Reads a PDF file directly from FastAPI's UploadFile stream,
    extracts text, and truncates it to max_chars (default 25000).
    """
    extracted_text = ""
    
    # Check if the file is a PDF
    if uploaded_file.content_type != "application/pdf":
        return extracted_text

    try:
        # Read the file bytes asynchronously
        file_bytes = await uploaded_file.read()
        
        # Reset the file cursor in case we need to save it later in the route
        await uploaded_file.seek(0)
        
        # Process PDF in memory
        pdf_reader = PyPDF2.PdfReader(io.BytesIO(file_bytes))
        
        for page in pdf_reader.pages:
            text = page.extract_text()
            if text:
                extracted_text += text + "\n"
                
            # Performance Optimization: Stop parsing if we already hit the limit
            if len(extracted_text) >= max_chars:
                break
                
        # Exact Node.js replication: return the substring strictly limited to max_chars
        return extracted_text[:max_chars]
        
    except Exception as e:
        print(f"PDF parse warning: {str(e)}")
        return ""
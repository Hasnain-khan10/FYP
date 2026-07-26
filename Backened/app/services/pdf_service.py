import os
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

def generate_quiz_pdf_file(quiz_data: dict, file_path: str):
    doc = SimpleDocTemplate(file_path, pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
    styles = getSampleStyleSheet()
    story = []

    title_style = ParagraphStyle('TitleStyle', parent=styles['Heading1'], fontSize=20, alignment=1, spaceAfter=10)
    heading_style = ParagraphStyle('HeadingStyle', parent=styles['Heading2'], fontSize=14, spaceBefore=15, spaceAfter=5, textColor=colors.HexColor('#003366'))
    normal_style = styles['Normal']
    bold_style = ParagraphStyle('BoldStyle', parent=styles['Normal'], fontName='Helvetica-Bold')

    # Student Paper
    story.append(Paragraph(quiz_data.get("title", "Examination Paper"), title_style))
    story.append(Paragraph(quiz_data.get("description", ""), styles['Italic']))
    story.append(Spacer(1, 15))

    # MCQs
    questions = quiz_data.get("questions", [])
    if questions:
        story.append(Paragraph("SECTION A: Multiple Choice Questions", heading_style))
        for idx, q in enumerate(questions, 1):
            story.append(Paragraph(f"<b>Q{idx}. {q.get('question')}</b> ({q.get('marks', 1)} Marks)", normal_style))
            opts = q.get("options", {})
            for key in ["A", "B", "C", "D"]:
                if key in opts:
                    story.append(Paragraph(f"{key}. {opts[key]}", normal_style))
            story.append(Spacer(1, 8))

    # Short Questions
    shorts = quiz_data.get("shortQuestions", []) or quiz_data.get("short_questions", [])
    if shorts:
        story.append(Paragraph("SECTION B: Short Answer Questions", heading_style))
        for idx, q in enumerate(shorts, 1):
            story.append(Paragraph(f"<b>Q{idx}. {q.get('question')}</b> ({q.get('marks', 2)} Marks)", normal_style))
            story.append(Spacer(1, 20))

    # Long Questions
    longs = quiz_data.get("longQuestions", []) or quiz_data.get("long_questions", [])
    if longs:
        story.append(Paragraph("SECTION C: Long Answer Questions", heading_style))
        for idx, q in enumerate(longs, 1):
            story.append(Paragraph(f"<b>Q{idx}. {q.get('question')}</b> ({q.get('marks', 5)} Marks)", normal_style))
            story.append(Spacer(1, 40))

    # Teacher Answer Key (Page Break)
    story.append(PageBreak())
    story.append(Paragraph("INSTRUCTOR ONLY - ANSWER KEY & RUBRIC", ParagraphStyle('RedTitle', parent=title_style, textColor=colors.red)))
    story.append(Spacer(1, 15))

    if questions:
        story.append(Paragraph("MCQ Solutions & Rationale", heading_style))
        for idx, q in enumerate(questions, 1):
            story.append(Paragraph(f"<b>Q{idx}. Correct: {q.get('correctAnswer')}</b>", bold_style))
            story.append(Paragraph(f"Rationale: {q.get('explanation', 'N/A')}", normal_style))
            story.append(Spacer(1, 6))

    if shorts or longs:
        story.append(Paragraph("Descriptive Questions - Grading Guide", heading_style))
        for idx, q in enumerate(shorts + longs, 1):
            story.append(Paragraph(f"<b>Q{idx}. Ideal Answer:</b> {q.get('idealAnswer', 'N/A')}", normal_style))
            story.append(Paragraph(f"<b>Rubric:</b> {q.get('rubric', 'N/A')}", normal_style))
            story.append(Spacer(1, 8))

    doc.build(story)
    return file_path
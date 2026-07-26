from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.quiz import Quiz
from app.services.llm_service import call_ai
from app.services.document_processor import extract_text_from_pdf

router = APIRouter()

# ====================================================
# 🤖 AI MCQ QUIZ GENERATION ENDPOINT
# ====================================================
@router.post("/quizzes/mcq")
async def create_ai_mcq_quiz(
    # Form fields (Node.js req.body)
    topic: Optional[str] = Form(None),
    prompt: Optional[str] = Form(None),
    courseTitle: Optional[str] = Form(None),
    difficulty: Optional[str] = Form("hard"),
    questionCount: Optional[int] = Form(10),
    marksPerQuestion: Optional[int] = Form(1),
    openDateTime: Optional[datetime] = Form(None),
    deadlineDateTime: Optional[datetime] = Form(None),
    # File upload (Node.js req.file)
    book: Optional[UploadFile] = File(None),
    # Dependencies
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 1. Resolve Final Topic
    final_topic = topic or prompt or courseTitle or "General Evaluation"
    if not final_topic.strip():
        final_topic = "Evaluation strictly based on attached file" if book else "General Course Evaluation"
        
    # 2. Extract PDF Text (if uploaded)
    extracted_text = ""
    if book and book.filename:
        extracted_text = await extract_text_from_pdf(book)
        
    # 3. Construct the Groq Prompt (Exact Node.js map)
    groq_prompt = f"""You are a Lead Examination Board Setter for a University.
Create a highly analytical Multiple Choice Question (MCQ) exam.
Topic: {final_topic}
Difficulty: {difficulty}
Total MCQs: {questionCount}
"""
    if extracted_text:
        groq_prompt += f"Reference Context Data:\n{extracted_text}\n\n"
        
    groq_prompt += f"""STRICT RULES:
1. Options must contain strong plausible distractors.
2. The explanation must clearly state WHY the correct option is right.
3. Return ONLY clean JSON.
JSON Format Layout:
{{ "title": "Analytical MCQ Assessment: {final_topic}", "description": "High-level cognitive evaluation paper.", "questions": [ {{ "question": "Deep analytical question text?", "options": {{ "A": "Option A", "B": "Option B", "C": "Option C", "D": "Option D" }}, "correctAnswer": "A", "explanation": "Detailed rationale explaining the correct concept." }} ] }}"""

    # 4. Call Hybrid AI Engine
    try:
        ai_data = await call_ai(prompt=groq_prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Generation Error: {str(e)}")
        
    if not ai_data or "questions" not in ai_data:
        raise HTTPException(status_code=500, detail="Invalid JSON structure from AI")
        
    # 5. Format Questions Array
    formatted_questions = []
    for q in ai_data.get("questions", [])[:questionCount]:
        formatted_questions.append({
            "question": q.get("question", "Core evaluation query"),
            "options": {
                "A": q.get("options", {}).get("A", "N/A"),
                "B": q.get("options", {}).get("B", "N/A"),
                "C": q.get("options", {}).get("C", "N/A"),
                "D": q.get("options", {}).get("D", "N/A")
            },
            "correctAnswer": q.get("correctAnswer", "A"),
            "explanation": q.get("explanation", "Correct answer mapped dynamically."),
            "marks": marksPerQuestion
        })
        
    total_marks = len(formatted_questions) * marksPerQuestion
    
    # 6. Save to PostgreSQL Database
    db_quiz = Quiz(
        teacher_id=current_user.id,
        title=ai_data.get("title", f"{final_topic} Assessment"),
        description=ai_data.get("description", "University Level MCQ Exam"),
        type="mcq",
        questions=formatted_questions,
        total_marks=total_marks,
        marks_per_question=marksPerQuestion,
        is_ai_scanned=False,
        exam_meta={"type": "MCQ_EXAM", "generatedBy": "GROQ_AI"},
        open_date_time=openDateTime,
        deadline_date_time=deadlineDateTime
    )
    
    db.add(db_quiz)
    db.commit()
    db.refresh(db_quiz)
    
    # Note: PDF Generator Utility aur Firebase Notification main iske baad convert karunga
    
    return {
        "success": True,
        "message": "MCQ generated perfectly",
        "quiz": db_quiz
    }

from app.models.plan import WeekPlan

# ====================================================
# 🤖 AI DESCRIPTIVE (SHORT/LONG) QUIZ GENERATION ENDPOINT
# ====================================================
@router.post("/quizzes/descriptive")
async def create_ai_question_quiz(
    topic: Optional[str] = Form(None),
    prompt: Optional[str] = Form(None),
    courseTitle: Optional[str] = Form(None),
    difficulty: Optional[str] = Form("hard"),
    shortCount: Optional[int] = Form(0),
    longCount: Optional[int] = Form(0),
    shortEachMark: Optional[int] = Form(2),
    longEachMark: Optional[int] = Form(5),
    type: Optional[str] = Form("long"),
    openDateTime: Optional[datetime] = Form(None),
    deadlineDateTime: Optional[datetime] = Form(None),
    book: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    final_topic = topic or prompt or courseTitle or "General Subjective Assessment"
    s_count, l_count = shortCount or 0, longCount or 0
    s_each, l_each = shortEachMark or 2, longEachMark or 5
    
    extracted_text = ""
    if book and book.filename:
        extracted_text = await extract_text_from_pdf(book)

    if type == "short":
        format_req = f'Generate EXACTLY {s_count} short questions. \nJSON Layout:\n{{ "title": "...", "description": "...", "shortQuestions": [{{ "question": "...", "marks": {s_each}, "idealAnswer": "...", "rubric": "..." }}] }}'
    elif type == "long":
        format_req = f'Generate EXACTLY {l_count} long questions. \nJSON Layout:\n{{ "title": "...", "description": "...", "longQuestions": [{{ "question": "...", "marks": {l_each}, "idealAnswer": "...", "rubric": "..." }}] }}'
    else:
        format_req = f'Generate {s_count} short and {l_count} long questions. \nJSON Layout:\n{{ "title": "...", "description": "...", "shortQuestions": [{{ "question": "...", "marks": {s_each}, "idealAnswer": "...", "rubric": "..." }}], "longQuestions": [{{ "question": "...", "marks": {l_each}, "idealAnswer": "...", "rubric": "..." }}] }}'

    groq_prompt = f"""You are a Senior Academic Assessor. Generate descriptive exam questions.
Topic: {final_topic}
Difficulty: {difficulty}
"""
    if extracted_text:
        groq_prompt += f"Reference Text Context:\n{extracted_text}\n\n"
        
    groq_prompt += f"STRICT RULE: Respond with clean raw JSON only. Provide deeply detailed 'idealAnswer' and a specific 'rubric' for fair grading.\n{format_req}"

    try:
        ai_data = await call_ai(prompt=groq_prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Generation Error: {str(e)}")

    db_short = [{"question": q.get("question"), "marks": s_each, "idealAnswer": q.get("idealAnswer", "Brief solution."), "rubric": q.get("rubric", "Standard marks.")} for q in ai_data.get("shortQuestions", [])[:s_count]]
    db_long = [{"question": q.get("question"), "marks": l_each, "idealAnswer": q.get("idealAnswer", "Detailed solution."), "rubric": q.get("rubric", "Full architectural details.")} for q in ai_data.get("longQuestions", [])[:l_count]]
    
    total_marks = (len(db_short) * s_each) + (len(db_long) * l_each)

    db_quiz = Quiz(
        teacher_id=current_user.id,
        title=ai_data.get("title", f"Written Exam Paper for {final_topic}"),
        description=ai_data.get("description", "In-Depth Descriptive Assessment"),
        type="mixed" if type == "both" else "question",
        short_questions=db_short,
        long_questions=db_long,
        total_marks=total_marks,
        is_ai_scanned=False,
        open_date_time=openDateTime,
        deadline_date_time=deadlineDateTime
    )
    db.add(db_quiz)
    db.commit()
    db.refresh(db_quiz)

    return {"success": True, "message": "Quiz generated perfectly using Groq", "quiz": db_quiz}


# ====================================================
# 🤖 AI 18-WEEK CURRICULUM PLAN GENERATION ENDPOINT
# ====================================================
@router.post("/plans")
async def create_ai_plan(
    topic: Optional[str] = Form(None),
    teacherCustomPrompt: Optional[str] = Form(""),
    format: Optional[str] = Form("PDF"),
    book: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    final_topic = topic or teacherCustomPrompt or "General Course Plan"
    extracted_text = ""
    if book and book.filename:
        extracted_text = await extract_text_from_pdf(book)

    groq_prompt = f"""You are a Lead Academic Professor at a top-tier University.
Design a highly detailed, comprehensive 18-Week curriculum.
Course/Topic: {final_topic}
Special Instructions: {teacherCustomPrompt}
"""
    if extracted_text:
        groq_prompt += f"Reference Context:\n{extracted_text}\n\n"

    groq_prompt += """STRICT RULES:
1. Generate EXACTLY 18 weeks.
2. Output MUST be strictly valid raw JSON.
3. Provide IN-DEPTH and DETAILED academic definitions and explanations.
Return JSON format exactly like:
{ "title": "...", "description": "...", "weeks": [ { "weekNumber": 1, "title": "...", "definition": "...", "detailedExplanation": "...", "subTopics": ["..."], "typesOrClassifications": ["..."], "codeOrQuerySnippet": "...", "realWorldAnalogy": "..." } ] }"""

    try:
        ai_data = await call_ai(prompt=groq_prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Generation Error: {str(e)}")

    raw_weeks = ai_data.get("weeks", [])
    formatted_weeks = []
    for i in range(18):
        if i < len(raw_weeks):
            w = raw_weeks[i]
            formatted_weeks.append({
                "weekNumber": i + 1,
                "title": w.get("title", f"Week {i + 1}"),
                "definition": w.get("definition", "Definition pending."),
                "detailedExplanation": w.get("detailedExplanation", "Explanation pending."),
                "subTopics": w.get("subTopics", []) if isinstance(w.get("subTopics"), list) else [],
                "typesOrClassifications": w.get("typesOrClassifications", []) if isinstance(w.get("typesOrClassifications"), list) else [],
                "codeOrQuerySnippet": w.get("codeOrQuerySnippet", ""),
                "realWorldAnalogy": w.get("realWorldAnalogy", "")
            })
        else:
            formatted_weeks.append({
                "weekNumber": i + 1, "title": f"Week {i + 1}", "definition": "Pending",
                "detailedExplanation": "Pending", "subTopics": [], "typesOrClassifications": [],
                "codeOrQuerySnippet": "", "realWorldAnalogy": ""
            })

    new_plan = WeekPlan(
        teacher_id=current_user.id,
        title=ai_data.get("title", "18-Week Curriculum"),
        description=ai_data.get("description", "AI Generated Detailed Plan"),
        prompt=teacherCustomPrompt,
        output_format=format or "PDF",
        generation_source="book" if book else "prompt",
        weeks=formatted_weeks
    )
    db.add(new_plan)
    db.commit()
    db.refresh(new_plan)

    return {"success": True, "message": "18-week comprehensive plan generated perfectly.", "plan": new_plan}

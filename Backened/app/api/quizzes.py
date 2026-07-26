from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional, Dict
from datetime import datetime, timedelta, timezone
from pydantic import BaseModel
import os
import shutil
import json
import base64

from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.quiz import Quiz
from app.models.attempt import Attempt
from app.models.courses import Enrollment, Course
from app.services.pdf_service import generate_quiz_pdf_file
from app.services.llm_service import call_ai as generate_ai_response
from app.services.notification_service import NotificationService

router = APIRouter()

# --- SCHEMAS ---
class QuestionSchema(BaseModel):
    question: str
    options: Optional[Dict[str, str]] = None
    correctAnswer: Optional[str] = None
    explanation: Optional[str] = ""
    marks: int = 1

class SubjectiveQuestionSchema(BaseModel):
    question: str
    marks: int
    idealAnswer: Optional[str] = ""
    rubric: Optional[str] = ""

class ManualQuizCreate(BaseModel):
    courseId: int
    title: str
    type: str
    questions: Optional[List[QuestionSchema]] = []
    shortQuestions: Optional[List[SubjectiveQuestionSchema]] = []
    longQuestions: Optional[List[SubjectiveQuestionSchema]] = []
    openDateTime: Optional[datetime] = None
    deadlineDateTime: Optional[datetime] = None

class MCQAttemptReq(BaseModel):
    answers: List[Dict[str, str]]

class ManualMarksUpdateReq(BaseModel):
    manualScore: float
    questionIndex: Optional[int] = None


# ==========================================
# 0. GET ALL QUIZZES & GET QUIZZES BY COURSE
# ==========================================
@router.get("")
@router.get("/")
async def get_all_quizzes(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # 🔥 FIX: Student ko sirf enrolled courses ki quizzes jayengi, Teacher ko uski banai hui.
    if current_user.role == "teacher":
        quizzes = db.query(Quiz).filter(Quiz.teacher_id == current_user.id).all()
    else:
        enrollments = db.query(Enrollment).filter(Enrollment.user_id == current_user.id).all()
        course_ids = [e.course_id for e in enrollments]
        quizzes = db.query(Quiz).filter(Quiz.course_id.in_(course_ids)).all()
        
    return {"quizzes": quizzes}

@router.get("/course/{course_id}")
async def get_quizzes_by_course(course_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    quizzes = db.query(Quiz).filter(Quiz.course_id == course_id).all()
    return {"quizzes": quizzes}


# ==========================================
# 1. CREATE QUIZ
# ==========================================
@router.post("")
@router.post("/")
async def create_manual_quiz(
    quiz_data: ManualQuizCreate, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "teacher":
        raise HTTPException(status_code=403, detail="Only teachers can create quizzes.")

    current_time = datetime.now(timezone.utc)
    open_date = quiz_data.openDateTime or current_time
    deadline_date = quiz_data.deadlineDateTime or (current_time + timedelta(hours=24))

    total_marks = sum(q.marks for q in quiz_data.questions) if quiz_data.type in ["mcq", "mixed"] else 0
    if quiz_data.type in ["question", "mixed"]:
        total_marks += sum(q.marks for q in quiz_data.shortQuestions) + sum(q.marks for q in quiz_data.longQuestions)

    new_quiz = Quiz(
        course_id=quiz_data.courseId,
        teacher_id=current_user.id,
        title=quiz_data.title,
        type=quiz_data.type,
        questions=[q.model_dump() for q in quiz_data.questions],
        short_questions=[q.model_dump() for q in quiz_data.shortQuestions],
        long_questions=[q.model_dump() for q in quiz_data.longQuestions],
        total_marks=total_marks,
        is_ai_scanned=False,
        open_date_time=open_date,
        deadline_date_time=deadline_date
    )
    db.add(new_quiz)
    db.commit()
    db.refresh(new_quiz)

    # FCM Notification logic
    enrollments = db.query(Enrollment).filter(Enrollment.course_id == quiz_data.courseId).all()
    for e in enrollments:
        if e.student and e.student.fcmToken:
            await NotificationService.send_push_notification(
                fcm_token=e.student.fcmToken,
                title="New Quiz Posted! 📝",
                body=f"A new quiz '{new_quiz.title}' is available. Deadline: {deadline_date.strftime('%Y-%m-%d %H:%M')}",
                data_payload={"quizId": str(new_quiz.id), "type": "quiz_created"}
            )

    return {"success": True, "message": "Quiz configured successfully", "quiz": new_quiz}


# ==========================================
# 2. SCAN & GRADE PAPER VIA VISION AI ENGINE
# ==========================================
@router.post("/scan-ai")
async def scan_ai_quiz_marks(
    courseId: int = Form(...),
    studentId: int = Form(...),
    quizId: int = Form(...),
    questionIndex: int = Form(-1),
    questionText: str = Form(""),
    maxMarks: int = Form(5),
    files: List[UploadFile] = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "teacher":
        raise HTTPException(status_code=403, detail="Only teachers can scan and grade answer sheets.")

    quiz = db.query(Quiz).filter(Quiz.id == quizId).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    os.makedirs("uploads", exist_ok=True)
    saved_filenames = []
    base64_images = []

    for file in files:
        filename = f"q{questionIndex}-opt-{int(datetime.now().timestamp())}-{file.filename}"
        filepath = os.path.join("uploads", filename)
        
        file_bytes = await file.read()
        with open(filepath, "wb") as buffer:
            buffer.write(file_bytes)
            
        saved_filenames.append(filename)
        base64_str = base64.b64encode(file_bytes).decode('utf-8')
        base64_images.append(base64_str)

    vision_prompt = f"""
You are an expert, fair, and highly accurate University Examiner evaluating scanned handwritten exam answers.
Question: "{questionText}"
Maximum Marks: {maxMarks}.

Output your ENTIRE response as a SINGLE VALID JSON OBJECT ONLY:
{{"obtained_marks": <number>, "feedback": "<1-line honest and accurate feedback>"}}
"""

    try:
        ai_data = await generate_ai_response(prompt=vision_prompt, images=base64_images)
    except Exception as e:
        ai_data = {"obtained_marks": 0, "feedback": f"Evaluation error: {str(e)}"}

    obtained = min(float(ai_data.get("obtained_marks", 0)), float(maxMarks))

    attempt = db.query(Attempt).filter(Attempt.student_id == studentId, Attempt.quiz_id == quizId).first()
    
    if not attempt:
        all_qs = (quiz.short_questions or []) + (quiz.long_questions or [])
        initial_answers = [{
            "question_text": q.get("question"),
            "max_marks": q.get("marks", 5),
            "obtained_marks": 0,
            "scannedImage": None,
            "aiFeedback": ""
        } for q in all_qs]

        attempt = Attempt(
            student_id=studentId,
            quiz_id=quizId,
            answers=initial_answers,
            score=0,
            total=quiz.total_marks,
            evaluated_by_ai=True
        )
        db.add(attempt)
        db.commit()
        db.refresh(attempt)

    answers = list(attempt.answers)
    if 0 <= questionIndex < len(answers):
        answers[questionIndex]["obtained_marks"] = obtained
        answers[questionIndex]["scannedImage"] = saved_filenames[0]
        answers[questionIndex]["aiFeedback"] = ai_data.get("feedback", "Checked via AI Scanner.")
        answers[questionIndex]["isCorrect"] = (obtained > 0)

    attempt.answers = answers
    attempt.score = sum(a.get("obtained_marks", 0) for a in answers)
    attempt.evaluated_by_ai = True
    quiz.is_ai_scanned = True

    db.commit()

    student = db.query(User).filter(User.id == studentId).first()
    if student and student.fcmToken:
        await NotificationService.send_push_notification(
            fcm_token=student.fcmToken,
            title="Paper Evaluated 🤖",
            body=f"Your answer for '{quiz.title}' has been graded.",
            data_payload={"quizId": str(quizId), "type": "result"}
        )

    return {"message": "Question Scanned Successfully", "score": attempt.score, "aiFeedback": ai_data.get("feedback")}


# ==========================================
# 3. ATTEMPT MCQ QUIZ (STUDENT ONLY)
# ==========================================
@router.post("/{quiz_id}/attempt")
async def attempt_quiz(
    quiz_id: int, 
    attempt_data: MCQAttemptReq, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can attempt quizzes.")

    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    existing_attempt = db.query(Attempt).filter(Attempt.student_id == current_user.id, Attempt.quiz_id == quiz.id).first()
    if existing_attempt:
        raise HTTPException(status_code=400, detail="You have already attempted this quiz.")

    score = 0
    questions = quiz.questions or []
    review = []

    for idx, q in enumerate(questions):
        student_ans = attempt_data.answers[idx].get("selectedAnswer") if idx < len(attempt_data.answers) else None
        is_correct = (student_ans == q.get("correctAnswer"))
        if is_correct:
            score += q.get("marks", 1)
            
        review.append({
            "question": q.get("question"),
            "selectedAnswer": student_ans,
            "correctAnswer": q.get("correctAnswer"),
            "isCorrect": is_correct,
            "obtained_marks": q.get("marks", 1) if is_correct else 0
        })

    new_attempt = Attempt(
        student_id=current_user.id,
        quiz_id=quiz.id,
        answers=review,
        score=score,
        total=quiz.total_marks,
        evaluated_by_ai=False
    )
    db.add(new_attempt)
    db.commit()
    return {"message": "Quiz attempted successfully", "score": score, "total": len(questions), "review": review}


# ==========================================
# 4. GET QUIZ RESULTS & MARKS LOG
# ==========================================
@router.get("/{quiz_id}/results")
async def get_quiz_results(
    quiz_id: int, 
    request: Request, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    attempts = db.query(Attempt).filter(Attempt.quiz_id == quiz_id).all()
    base_url = str(request.base_url).rstrip("/")

    results = []
    for a in attempts:
        detailed_answers = []
        for ans in (a.answers or []):
            img_url = f"{base_url}/uploads/{ans.get('scannedImage')}" if ans.get('scannedImage') else None
            detailed_answers.append({
                "question_text": ans.get("question_text") or ans.get("question"),
                "student_answer": ans.get("selectedAnswer") or "",
                "obtained_marks": ans.get("obtained_marks", 0),
                "max_marks": ans.get("max_marks", 0),
                "scannedImageUrl": img_url,
                "aiFeedback": ans.get("aiFeedback", "")
            })

        results.append({
            "attemptId": a.id,
            "studentId": a.student_id,
            "studentName": a.student.name if a.student else "Unknown",
            "score": a.score,
            "totalMarks": a.total,
            "evaluatedByAI": a.evaluated_by_ai,
            "detailedAnswers": detailed_answers
        })

    return {"quiz": {"id": quiz.id, "title": quiz.title, "totalMarks": quiz.total_marks}, "results": results}


# ==========================================
# 5. TEACHER MANUAL MARKS OVERRIDE
# ==========================================
@router.put("/attempts/{attempt_id}/marks")
async def update_manual_marks(
    attempt_id: int, 
    data: ManualMarksUpdateReq, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "teacher":
        raise HTTPException(status_code=403, detail="Only instructors can modify marks.")

    attempt = db.query(Attempt).filter(Attempt.id == attempt_id).first()
    if not attempt:
        raise HTTPException(status_code=404, detail="Attempt not found")

    answers = list(attempt.answers)
    if data.questionIndex is not None and 0 <= data.questionIndex < len(answers):
        answers[data.questionIndex]["obtained_marks"] = data.manualScore
        attempt.answers = answers
        attempt.score = sum(a.get("obtained_marks", 0) for a in answers)
    else:
        attempt.score = data.manualScore

    db.commit()
    return {"message": "Marks updated successfully!", "score": attempt.score}


# ==========================================
# 6. DELETE QUIZ
# ==========================================
@router.delete("/{quiz_id}")
async def delete_quiz(
    quiz_id: int, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "teacher":
        raise HTTPException(status_code=403, detail="Only instructors can delete quizzes.")

    quiz = db.query(Quiz).filter(Quiz.id == quiz_id, Quiz.teacher_id == current_user.id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    enrollments = db.query(Enrollment).filter(Enrollment.course_id == quiz.course_id).all()
    for e in enrollments:
        if e.student and e.student.fcmToken:
            await NotificationService.send_push_notification(
                fcm_token=e.student.fcmToken,
                title="Quiz Cancelled 🚫",
                body=f"The quiz '{quiz.title}' has been deleted.",
                data_payload={"type": "quiz_deleted"}
            )

    db.delete(quiz)
    db.commit()
    return {"message": "Quiz deleted successfully"}
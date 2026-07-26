from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
import secrets

from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.courses import Course, Enrollment
from app.models.plan import WeekPlan
from app.models.quiz import Quiz
from app.services.notification_service import NotificationService

router = APIRouter()

class CourseCreate(BaseModel):
    title: str
    courseCode: str
    creditHours: int
    syllabus: Optional[str] = ""
    semester: str
    books: Optional[List[str]] = []

class JoinCourseReq(BaseModel):
    code: str


@router.post("")
@router.post("/")
async def create_course(course_data: CourseCreate, request: Request, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "teacher":
        raise HTTPException(status_code=403, detail="Forbidden: Only instructors can build courses.")

    while True:
        new_code = secrets.token_hex(4)
        if not db.query(Course).filter(Course.join_code == new_code).first():
            break

    new_course = Course(
        title=course_data.title, course_code=course_data.courseCode, credit_hours=course_data.creditHours,
        syllabus=course_data.syllabus, semester=course_data.semester, books=course_data.books,
        teacher_id=current_user.id, join_code=new_code
    )
    db.add(new_course)
    db.commit()
    db.refresh(new_course)
    
    base_url = str(request.base_url).rstrip("/")
    join_link = f"{base_url}/api/courses/join/{new_code}"
    return {"success": True, "message": "Course created successfully", "course": new_course, "joinLink": join_link}


@router.post("/join")
async def join_course(req_data: JoinCourseReq, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Forbidden: Only students can register.")

    course = db.query(Course).filter(Course.join_code == req_data.code.strip()).first()
    if not course:
        raise HTTPException(status_code=404, detail="Invalid join code.")

    if db.query(Enrollment).filter(Enrollment.user_id == current_user.id, Enrollment.course_id == course.id).first():
        raise HTTPException(status_code=400, detail="You are already enrolled in this course.")

    enrollment = Enrollment(user_id=current_user.id, course_id=course.id, progress=0)
    db.add(enrollment)
    db.commit()

    teacher = db.query(User).filter(User.id == course.teacher_id).first()
    
    # 🔥 FIX: Use exactly "fcmToken" as defined in User Model
    if teacher and teacher.fcmToken:
        await NotificationService.send_push_notification(
            fcm_token=teacher.fcmToken, title="New Student Enrolled 🎓",
            body=f"{current_user.name} has joined your course '{course.title}'.",
            data_payload={"courseId": str(course.id), "type": "course"}
        )

    return {"success": True, "message": "Joined successfully", "courseId": course.id}


@router.get("")
@router.get("/")
async def get_courses(request: Request, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    base_url = str(request.base_url).rstrip("/")
    if current_user.role == "teacher":
        courses = db.query(Course).filter(Course.teacher_id == current_user.id).all()
    else:
        enrollments = db.query(Enrollment).filter(Enrollment.user_id == current_user.id).all()
        course_ids = [e.course_id for e in enrollments]
        courses = db.query(Course).filter(Course.id.in_(course_ids)).all()

    return {"success": True, "courses": [{
        "id": c.id, "title": c.title, "courseCode": c.course_code, "creditHours": c.credit_hours,
        "semester": c.semester, "joinCode": c.join_code, "joinLink": f"{base_url}/api/courses/join/{c.join_code}"
    } for c in courses]}


@router.get("/{course_id}/students")
async def get_course_students(course_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "teacher":
        raise HTTPException(status_code=403, detail="Only teachers can access students logs.")
    course = db.query(Course).filter(Course.id == course_id, Course.teacher_id == current_user.id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found.")
    enrollments = db.query(Enrollment).filter(Enrollment.course_id == course_id).all()
    return {"success": True, "students": [{"id": e.student.id, "name": e.student.name, "email": e.student.email, "progress": e.progress} for e in enrollments]}


@router.delete("/{course_id}")
async def delete_course(course_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "teacher":
        raise HTTPException(status_code=403, detail="Action Unauthorized.")
    course = db.query(Course).filter(Course.id == course_id, Course.teacher_id == current_user.id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course scope missing.")

    enrollments = db.query(Enrollment).filter(Enrollment.course_id == course_id).all()
    for e in enrollments:
        # 🔥 FIX: Changed fcm_token to fcmToken
        if e.student and e.student.fcmToken:
            await NotificationService.send_push_notification(
                fcm_token=e.student.fcmToken, title="Course Deleted ⚠️",
                body=f"Instructor removed the course '{course.title}'.",
                data_payload={"type": "course_deleted"}
            )

    db.query(WeekPlan).filter(WeekPlan.course_id == course_id).delete()
    db.query(Quiz).filter(Quiz.course_id == course_id).delete()
    db.query(Enrollment).filter(Enrollment.course_id == course_id).delete()
    db.delete(course)
    db.commit()
    return {"success": True, "message": "Deleted successfully."}
import asyncio
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.quiz import Quiz
from app.models.courses import Enrollment
from app.services.notification_service import NotificationService

async def check_deadlines():
    db: Session = SessionLocal()
    try:
        current_time = datetime.now(timezone.utc)
        # Find quizzes where deadline passed AND hasn't been notified yet
        expired_quizzes = db.query(Quiz).filter(
            Quiz.deadline_date_time <= current_time,
            Quiz.deadline_notified == False
        ).all()

        for quiz in expired_quizzes:
            enrollments = db.query(Enrollment).filter(Enrollment.course_id == quiz.course_id).all()
            for e in enrollments:
                # 🔥 FIX: Read User.fcmToken (camelCase) instead of fcm_token
                if e.student and e.student.fcmToken:
                    await NotificationService.send_push_notification(
                        fcm_token=e.student.fcmToken,
                        title="Quiz Deadline Expired ⏰",
                        body=f"The deadline for '{quiz.title}' has passed.",
                        data_payload={"quizId": str(quiz.id), "type": "deadline"}
                    )
            
            # 🔥 LOCK SYSTEM: Flag updated so it never sends again!
            quiz.deadline_notified = True
        
        db.commit()
    except Exception as e:
        print(f"Deadline Scheduler Error: {e}")
    finally:
        db.close()
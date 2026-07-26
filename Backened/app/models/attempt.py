from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, JSON, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base

class Attempt(Base):
    __tablename__ = "attempts"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False)
    
    # Store array of answer objects (selectedAnswer, question_text, obtained_marks, max_marks, scannedImage, aiFeedback)
    answers = Column(JSON, default=[]) 
    
    score = Column(Integer, default=0)
    total = Column(Integer, default=0)
    evaluated_by_ai = Column(Boolean, default=False)
    scanned_paper = Column(JSON, default=[]) # Store list of image file paths

    # Unique constraint (one student can attempt a quiz only once)
    __table_args__ = (UniqueConstraint('student_id', 'quiz_id', name='_student_quiz_uc'),)

    # Relationships
    student = relationship("User", backref="quiz_attempts")
    quiz = relationship("Quiz", backref="student_attempts")
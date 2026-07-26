from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Keys (Relations)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False, index=True) 
    teacher_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Basic Info
    title = Column(String, nullable=False)
    description = Column(String, default="")
    type = Column(String, nullable=False) # enum: mcq, question, mixed
    
    # JSON Fields for PostgreSQL
    questions = Column(JSON, default=list)
    short_questions = Column(JSON, default=list)
    long_questions = Column(JSON, default=list)
    exam_meta = Column(JSON, default=dict)
    
    # Marks & Meta
    total_marks = Column(Integer, default=0)
    marks_per_question = Column(Integer, default=1)
    is_ai_scanned = Column(Boolean, default=False)
    
    # AUTOMATED TIME-BASED LOCK/UNLOCK FIELDS
    open_date_time = Column(DateTime(timezone=True), nullable=True)
    deadline_date_time = Column(DateTime(timezone=True), nullable=True)
    
    # 🔥 FIX: Added missing notification flag column referenced by Scheduler!
    deadline_notified = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    course = relationship("Course", backref="course_quizzes")
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.sql import func
from app.database import Base

class WeekPlan(Base):
    __tablename__ = "week_plans"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Keys
    course_id = Column(Integer, index=True) 
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # Basic Info
    title = Column(String, default="Premium 18-Week Lecture Series")
    description = Column(Text, default="")
    
    # AI Tracking
    prompt = Column(Text, default="")
    generation_source = Column(String, default="prompt") # prompt, book, both
    output_format = Column(String, default="PDF") # PDF, DOCX, PPT
    
    # File Tracking
    book_file_url = Column(String, nullable=True)
    book_file_type = Column(String, nullable=True)
    book_extracted_text = Column(Text, default="")
    
    # 🔥 Array of Objects (weeks) Converted to JSON
    weeks = Column(JSON, default=list)
    
    # Plan Meta
    semester_duration = Column(Integer, default=18)
    document_url = Column(String, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
from sqlalchemy import Column, Integer, String, ForeignKey, JSON
from sqlalchemy.orm import relationship
import secrets
from app.database import Base

class Enrollment(Base):
    __tablename__ = "enrollments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    progress = Column(Integer, default=0)

    # Relationships
    student = relationship("User", backref="enrollments")
    course = relationship("Course", backref="enrolled_students")

class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    course_code = Column(String, nullable=False)
    credit_hours = Column(Integer, nullable=False)
    syllabus = Column(String, nullable=True)
    semester = Column(String, nullable=False)
    books = Column(JSON, default=[]) # Storing array of strings
    teacher_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    join_code = Column(String, unique=True, index=True, nullable=False)

    # Relationships
    teacher = relationship("User", backref="teaching_courses")
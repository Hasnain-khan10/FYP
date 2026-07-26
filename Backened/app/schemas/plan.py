from pydantic import BaseModel
from typing import Optional

# 📝 18-Week Plan Request Body
class PlanCreate(BaseModel):
    courseId: Optional[str] = None
    topic: Optional[str] = None
    teacherCustomPrompt: Optional[str] = ""
    format: Optional[str] = "PDF"

# 📝 Course AI Generation Request Body
class CourseCreate(BaseModel):
    topic: str
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# 📝 MCQ Quiz Upload Request Body (Node.js req.body map)
class MCQQuizCreate(BaseModel):
    courseId: Optional[str] = None
    topic: Optional[str] = None
    prompt: Optional[str] = None
    courseTitle: Optional[str] = None
    difficulty: Optional[str] = "hard"
    questionCount: Optional[int] = 10
    marksPerQuestion: Optional[int] = 1
    openDateTime: Optional[datetime] = None
    deadlineDateTime: Optional[datetime] = None

# 📝 Subjective (Short/Long) Quiz Upload Request Body
class SubjectiveQuizCreate(BaseModel):
    courseId: Optional[str] = None
    topic: Optional[str] = None
    prompt: Optional[str] = None
    courseTitle: Optional[str] = None
    difficulty: Optional[str] = "hard"
    shortCount: Optional[int] = 0
    longCount: Optional[int] = 0
    shortEachMark: Optional[int] = 2
    longEachMark: Optional[int] = 5
    type: Optional[str] = "long"  # short, long, ya both
    openDateTime: Optional[datetime] = None
    deadlineDateTime: Optional[datetime] = None
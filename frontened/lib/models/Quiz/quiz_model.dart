class Quiz {
  final String id;
  final String title;
  final String description;
  final String type;
  final int totalMarks;
  final List<McqQuestion> questions;
  final List<SubjectiveQuestion> shortQuestions;
  final List<SubjectiveQuestion> longQuestions;
  final bool isAIScanned;
  final DateTime? createdAt;

  final String? course;
  final bool isCompleted;
  final num? score;
  final List<dynamic>? selectedAnswers;
  final bool? evaluatedByAI;
  final List<String>? scannedPaperUrls;

  final DateTime? openDateTime;
  final DateTime? deadlineDateTime;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.totalMarks,
    required this.questions,
    required this.shortQuestions,
    required this.longQuestions,
    required this.isAIScanned,
    this.createdAt,
    this.course,
    this.isCompleted = false,
    this.score,
    this.selectedAnswers,
    this.evaluatedByAI,
    this.scannedPaperUrls,
    this.openDateTime,
    this.deadlineDateTime,
  });

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) {
      if (val.trim().isEmpty) return null;
      try {
        return DateTime.parse(val).toLocal();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    String? parsedCourse;
    if (json['course'] is Map) {
      parsedCourse = (json['course']['_id'] ?? json['course']['id'])?.toString();
    } else if (json['course_id'] != null) {
      parsedCourse = json['course_id'].toString();
    } else if (json['course'] != null) {
      parsedCourse = json['course'].toString();
    }

    return Quiz(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled Quiz').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'mcq').toString(),
      totalMarks: int.tryParse((json['totalMarks'] ?? json['total_marks'] ?? 0).toString()) ?? 0,
      isAIScanned: json['isAIScanned'] == true || json['is_ai_scanned'] == true,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      course: parsedCourse,
      isCompleted: json['isCompleted'] == true,
      score: json['score'] != null ? num.tryParse(json['score'].toString()) : null,
      selectedAnswers: json['answers'] ?? json['selectedAnswers'],
      evaluatedByAI: json['evaluatedByAI'] == true || json['evaluated_by_ai'] == true,

      openDateTime: _parseDate(json['openDateTime'] ?? json['open_date_time']),
      deadlineDateTime: _parseDate(json['deadlineDateTime'] ?? json['deadline_date_time']),

      scannedPaperUrls: json['scannedPaper'] != null && json['scannedPaper'] is List
          ? List<String>.from((json['scannedPaper'] as List).map((file) => "https://smart-teacher-assistant-fyp.onrender.com/uploads/$file"))
          : [],

      questions: (json['questions'] is List)
          ? (json['questions'] as List).map((q) => McqQuestion.fromJson(q is Map<String, dynamic> ? q : Map<String, dynamic>.from(q))).toList()
          : [],
      shortQuestions: ((json['shortQuestions'] ?? json['short_questions']) is List)
          ? ((json['shortQuestions'] ?? json['short_questions']) as List).map((q) => SubjectiveQuestion.fromJson(q is Map<String, dynamic> ? q : Map<String, dynamic>.from(q))).toList()
          : [],
      longQuestions: ((json['longQuestions'] ?? json['long_questions']) is List)
          ? ((json['longQuestions'] ?? json['long_questions']) as List).map((q) => SubjectiveQuestion.fromJson(q is Map<String, dynamic> ? q : Map<String, dynamic>.from(q))).toList()
          : [],
    );
  }
}

class McqQuestion {
  final String question;
  final Map<String, String> options;
  final String correctAnswer;
  final String explanation;
  final int marks;

  McqQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.marks,
  });

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    Map<String, String> opts = {};
    if (json['options'] is Map) {
      (json['options'] as Map).forEach((key, value) {
        opts[key.toString()] = value.toString();
      });
    }

    return McqQuestion(
      question: (json['question'] ?? '').toString(),
      options: opts,
      correctAnswer: (json['correctAnswer'] ?? json['correct_answer'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      marks: int.tryParse((json['marks'] ?? 1).toString()) ?? 1,
    );
  }
}

class SubjectiveQuestion {
  final String question;
  final int marks;
  final String idealAnswer;
  final String rubric;

  SubjectiveQuestion({
    required this.question,
    required this.marks,
    required this.idealAnswer,
    required this.rubric,
  });

  factory SubjectiveQuestion.fromJson(Map<String, dynamic> json) {
    return SubjectiveQuestion(
      question: (json['question'] ?? '').toString(),
      marks: int.tryParse((json['marks'] ?? 0).toString()) ?? 0,
      idealAnswer: (json['idealAnswer'] ?? json['ideal_answer'] ?? '').toString(),
      rubric: (json['rubric'] ?? '').toString(),
    );
  }
}
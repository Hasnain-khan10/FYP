class CourseModel {
  final String id;
  final String title;
  final String courseCode;
  final int creditHours;
  final String syllabus;
  final List<String> books;

  final String? joinCode;
  final String? joinLink;
  final double progress;

  final String? semester;

  final String? teacherId;
  final String? teacherName;
  final String? teacherEmail;

  CourseModel({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.creditHours,
    required this.syllabus,
    required this.books,
    this.joinCode,
    this.joinLink,
    required this.progress,
    this.semester,
    this.teacherId,
    this.teacherName,
    this.teacherEmail,
  });

  factory CourseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) throw Exception("CourseModel.fromJson received null");

    final rawProgress = json['progress'];
    double parsedProgress = rawProgress != null ? (rawProgress as num).toDouble() : 0;

    final teacher = json['teacher'];
    final teacherMap = teacher is Map<String, dynamic> ? teacher : null;

    return CourseModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      courseCode: (json['courseCode'] ?? '').toString(),
      creditHours: (json['creditHours'] as num?)?.toInt() ?? int.tryParse(json['creditHours']?.toString() ?? '') ?? 0,
      syllabus: (json['syllabus'] ?? '').toString(),
      books: (json['books'] is List) ? (json['books'] as List).map((e) => e.toString()).toList() : [],
      joinCode: json['joinCode']?.toString(),
      joinLink: json['joinLink']?.toString(),
      progress: parsedProgress.clamp(0.0, 100.0),
      semester: json['semester']?.toString(),
      teacherId: teacher is String ? teacher : teacherMap?['_id']?.toString(),
      teacherName: teacherMap?['name']?.toString(),
      teacherEmail: teacherMap?['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "courseCode": courseCode,
      "creditHours": creditHours,
      "syllabus": syllabus,
      "books": books,
      "semester": semester,
    };
  }

  CourseModel copyWith({String? title, double? progress, String? joinLink}) {
    return CourseModel(
      id: id,
      title: title ?? this.title,
      courseCode: courseCode,
      creditHours: creditHours,
      syllabus: syllabus,
      books: books,
      joinCode: joinCode,
      joinLink: joinLink ?? this.joinLink,
      progress: progress ?? this.progress,
      semester: semester,
      teacherId: teacherId,
      teacherName: teacherName,
      teacherEmail: teacherEmail,
    );
  }
}
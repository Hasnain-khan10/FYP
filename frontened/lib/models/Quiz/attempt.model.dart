import 'Attempt_Review.dart';

class Attempt {
  final String id;
  final String quiz;
  final String student;
  final int score;
  final int total;
  final bool evaluatedByAI;
  final String scannedPaper;
  final List<AttemptReview> review;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attempt({
    required this.id,
    required this.quiz,
    required this.student,
    required this.score,
    required this.total,
    required this.evaluatedByAI,
    required this.scannedPaper,
    required this.review,
    this.createdAt,
    this.updatedAt,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      id: json['_id'] ?? '',
      quiz: json['quiz']?.toString() ?? '',
      student: json['student']?.toString() ?? '',
      score: json['score'] ?? 0,
      total: json['total'] ?? 0,
      evaluatedByAI: json['evaluatedByAI'] ?? false,
      scannedPaper: json['scannedPaper'] ?? '',
      review: json['review'] != null ? List<AttemptReview>.from((json['review'] as List).map((x) => AttemptReview.fromJson(x))) : [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
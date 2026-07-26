class SlideItem {
  final String title;
  final List<String> content;

  SlideItem({required this.title, required this.content});

  factory SlideItem.fromJson(Map<String, dynamic> json) {
    return SlideItem(
      title: json['title'] ?? '',
      content: List<String>.from(json['content'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {"title": title, "content": content};
}

class SlideModel {
  final String id;
  final String courseId;
  final String topic;
  final List<SlideItem> slides;
  final String? pptUrl;
  final String? teacherName;
  final String? teacherEmail;

  SlideModel({
    required this.id, required this.courseId, required this.topic,
    required this.slides, this.pptUrl, this.teacherName, this.teacherEmail,
  });

  factory SlideModel.fromJson(Map<String, dynamic> json) {
    return SlideModel(
      id: json['_id'] ?? '',
      courseId: json['course'] ?? '',
      topic: json['topic'] ?? '',
      slides: (json['slides'] as List?)?.map((s) => SlideItem.fromJson(s)).toList() ?? [],
      pptUrl: json['pptUrl'],
      teacherName: json['teacher'] is Map ? json['teacher']['name'] : null,
      teacherEmail: json['teacher'] is Map ? json['teacher']['email'] : null,
    );
  }
}
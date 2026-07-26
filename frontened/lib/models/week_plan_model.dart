class WeekPlanModel {
  final String id;
  final String title;
  final String description;
  final String documentUrl;
  final String outputFormat;
  final List<WeekModel> weeks;

  WeekPlanModel({
    required this.id,
    required this.title,
    required this.description,
    required this.documentUrl,
    required this.outputFormat,
    required this.weeks,
  });

  factory WeekPlanModel.fromJson(Map<String, dynamic> json) {
    return WeekPlanModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Week Plan',
      description: json['description'] ?? '',
      documentUrl: json['documentUrl'] ?? '',
      outputFormat: json['outputFormat'] ?? 'PDF',
      weeks: (json['weeks'] as List?)?.map((w) => WeekModel.fromJson(w)).toList() ?? [],
    );
  }
}

class WeekModel {
  final int weekNumber;
  final String title;
  final String definition;
  final String detailedExplanation;
  final List<String> subTopics;
  final String codeOrQuerySnippet;
  final String realWorldAnalogy;

  WeekModel({
    required this.weekNumber,
    required this.title,
    required this.definition,
    required this.detailedExplanation,
    required this.subTopics,
    required this.codeOrQuerySnippet,
    required this.realWorldAnalogy,
  });

  factory WeekModel.fromJson(Map<String, dynamic> json) {
    return WeekModel(
      weekNumber: json['weekNumber'] ?? 0,
      title: json['title'] ?? 'Untitled Week',
      definition: json['definition'] ?? '',
      detailedExplanation: json['detailedExplanation'] ?? '',
      subTopics: (json['subTopics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      codeOrQuerySnippet: json['codeOrQuerySnippet'] ?? '',
      realWorldAnalogy: json['realWorldAnalogy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "weekNumber": weekNumber,
      "title": title,
      "definition": definition,
      "detailedExplanation": detailedExplanation,
      "subTopics": subTopics,
      "codeOrQuerySnippet": codeOrQuerySnippet,
      "realWorldAnalogy": realWorldAnalogy,
    };
  }
}
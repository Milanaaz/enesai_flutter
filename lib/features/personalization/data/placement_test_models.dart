class PlacementTest {
  const PlacementTest({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final List<PlacementQuestion> questions;

  factory PlacementTest.fromJson(Map<String, dynamic> json) {
    return PlacementTest(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      questions:
          (json['questions'] is List<dynamic>
                  ? json['questions'] as List<dynamic>
                  : const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(PlacementQuestion.fromJson)
              .toList()
            ..sort(
              (PlacementQuestion a, PlacementQuestion b) =>
                  a.orderIndex.compareTo(b.orderIndex),
            ),
    );
  }
}

class PlacementQuestion {
  const PlacementQuestion({
    required this.id,
    required this.questionText,
    required this.audioUrl,
    required this.type,
    required this.level,
    required this.block,
    required this.orderIndex,
    required this.options,
  });

  final String id;
  final String questionText;
  final String audioUrl;
  final String type;
  final String level;
  final String block;
  final int orderIndex;
  final List<PlacementOption> options;

  factory PlacementQuestion.fromJson(Map<String, dynamic> json) {
    return PlacementQuestion(
      id: (json['id'] ?? '').toString(),
      questionText: (json['questionText'] ?? '').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      block: (json['block'] ?? '').toString(),
      orderIndex: int.tryParse((json['orderIndex'] ?? '0').toString()) ?? 0,
      options:
          (json['options'] is List<dynamic>
                  ? json['options'] as List<dynamic>
                  : const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(PlacementOption.fromJson)
              .toList()
            ..sort(
              (PlacementOption a, PlacementOption b) =>
                  a.orderIndex.compareTo(b.orderIndex),
            ),
    );
  }
}

class PlacementOption {
  const PlacementOption({
    required this.id,
    required this.text,
    required this.orderIndex,
  });

  final String id;
  final String text;
  final int orderIndex;

  factory PlacementOption.fromJson(Map<String, dynamic> json) {
    return PlacementOption(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      orderIndex: int.tryParse((json['orderIndex'] ?? '0').toString()) ?? 0,
    );
  }
}

class PlacementAnswer {
  const PlacementAnswer({
    required this.questionId,
    this.selectedOptionId,
    this.textAnswer,
  });

  final String questionId;
  final String? selectedOptionId;
  final String? textAnswer;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'questionId': questionId,
      if ((selectedOptionId ?? '').trim().isNotEmpty)
        'selectedOptionId': selectedOptionId,
      if ((textAnswer ?? '').trim().isNotEmpty) 'textAnswer': textAnswer,
    };
  }
}

class PlacementTestResult {
  const PlacementTestResult({
    required this.id,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.determinedLevel,
    required this.recommendedCourseTitle,
  });

  final String id;
  final int totalQuestions;
  final int correctAnswers;
  final int scorePercent;
  final String determinedLevel;
  final String recommendedCourseTitle;

  factory PlacementTestResult.fromJson(Map<String, dynamic> json) {
    return PlacementTestResult(
      id: (json['id'] ?? '').toString(),
      totalQuestions:
          int.tryParse((json['totalQuestions'] ?? '0').toString()) ?? 0,
      correctAnswers:
          int.tryParse((json['correctAnswers'] ?? '0').toString()) ?? 0,
      scorePercent: int.tryParse((json['scorePercent'] ?? '0').toString()) ?? 0,
      determinedLevel: (json['determinedLevel'] ?? '').toString(),
      recommendedCourseTitle: (json['recommendedCourseTitle'] ?? '').toString(),
    );
  }
}

/// AI 코치 피드백 모델
class CoachFeedback {
  final String title;
  final List<String> bullets;
  final String nextAction;
  final String toneTag;
  final DateTime timestamp;
  
  CoachFeedback({
    required this.title,
    required this.bullets,
    required this.nextAction,
    required this.toneTag,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'bullets': bullets,
      'nextAction': nextAction,
      'toneTag': toneTag,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory CoachFeedback.fromJson(Map<String, dynamic> json) {
    return CoachFeedback(
      title: json['title'] as String,
      bullets: (json['bullets'] as List<dynamic>).cast<String>(),
      nextAction: json['nextAction'] as String,
      toneTag: json['toneTag'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

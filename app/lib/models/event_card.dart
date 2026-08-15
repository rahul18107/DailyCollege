class EventCard {
  final String id;
  final String groupId;
  final String type;
  final String? subject;
  final String? date;
  final String description;
  final bool isTentative;
  final String? newTime;
  final String? syllabus;
  final String? sourceMsg;
  final String? sentBy;
  final String confidence;
  final DateTime generatedAt;
  final DateTime createdAt;
  final String? groupName;

  EventCard({
    required this.id,
    required this.groupId,
    required this.type,
    this.subject,
    this.date,
    required this.description,
    required this.isTentative,
    this.newTime,
    this.syllabus,
    this.sourceMsg,
    this.sentBy,
    required this.confidence,
    required this.generatedAt,
    required this.createdAt,
    this.groupName,
  });

  factory EventCard.fromJson(Map<String, dynamic> json) {
    return EventCard(
      id: json['id'],
      groupId: json['group_id'],
      type: json['type'],
      subject: json['subject'],
      date: json['date'],
      description: json['description'],
      isTentative: json['is_tentative'] ?? false,
      newTime: json['new_time'],
      syllabus: json['syllabus'],
      sourceMsg: json['source_msg'],
      sentBy: json['sent_by'],
      confidence: json['confidence'] ?? 'high',
      generatedAt: DateTime.parse(json['generated_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  EventCard withGroupName(String name) => EventCard(
        id: id,
        groupId: groupId,
        type: type,
        subject: subject,
        date: date,
        description: description,
        isTentative: isTentative,
        newTime: newTime,
        syllabus: syllabus,
        sourceMsg: sourceMsg,
        sentBy: sentBy,
        confidence: confidence,
        generatedAt: generatedAt,
        createdAt: createdAt,
        groupName: name,
      );
}
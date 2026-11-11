class QRHistoryModel {
  final int? id;
  final String content;
  final String qrType;
  final String actionType;
  final DateTime createdAt;

  QRHistoryModel({
    this.id,
    required this.content,
    required this.qrType,
    required this.actionType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'qrType': qrType,
      'actionType': actionType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QRHistoryModel.fromMap(Map<String, dynamic> map) {
    return QRHistoryModel(
      id: map['id'] as int?,
      content: map['content'] as String,
      qrType: map['qrType'] as String,
      actionType: map['actionType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

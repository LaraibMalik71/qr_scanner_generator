class SavedQRModel {
  final int? id;
  final String content;
  final String qrType;
  final DateTime createdAt;
  final bool isFavorite;

  SavedQRModel({
    this.id,
    required this.content,
    required this.qrType,
    required this.createdAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'qrType': qrType,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory SavedQRModel.fromMap(Map<String, dynamic> map) {
    return SavedQRModel(
      id: map['id'] as int?,
      content: map['content'] as String,
      qrType: map['qrType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }
}

// ==============================================================================
// Folder Model
// File: lib/data/models/folder_model.dart
//
// Represents a subject or course folder to organize Qayds (NFR10).
// ==============================================================================

class QaydFolder {
  final String id;
  final String name;
  final DateTime createdAt;

  const QaydFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QaydFolder.fromMap(Map<String, dynamic> map) {
    return QaydFolder(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'New Folder',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

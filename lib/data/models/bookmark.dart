import 'package:uuid/uuid.dart';

class Bookmark {
  final String id;
  final int pageNumber;
  final String note;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.pageNumber,
    required this.note,
    required this.createdAt,
  });

  factory Bookmark.create({
    required int pageNumber,
    String note = '',
  }) {
    return Bookmark(
      id: const Uuid().v4(),
      pageNumber: pageNumber,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  Bookmark copyWith({
    String? id,
    int? pageNumber,
    String? note,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'],
      pageNumber: map['pageNumber'],
      note: map['note'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// lib/data/models/novel.dart
import 'package:uuid/uuid.dart';

class Novel {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final DateTime createdAt;
  final DateTime lastReadAt;
  final int totalChapters;

  const Novel({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.createdAt,
    required this.lastReadAt,
    required this.totalChapters,
  });

  factory Novel.create({
    required String title,
    required String author,
    required String filePath,
  }) {
    return Novel(
      id: Uuid().v4(),
      title: title,
      author: author,
      filePath: filePath,
      createdAt: DateTime.now(),
      lastReadAt: DateTime.now(),
      totalChapters: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'lastReadAt': lastReadAt.toIso8601String(),
      'totalChapters': totalChapters,
    };
  }

  factory Novel.fromMap(Map<String, dynamic> map) {
    // 关键修复：移除了const关键字，因为map['id']等是运行时值，不是编译时常量
    return Novel(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      filePath: map['filePath'],
      createdAt: DateTime.parse(map['createdAt']),
      lastReadAt: DateTime.parse(map['lastReadAt']),
      totalChapters: map['totalChapters'],
    );
  }
}

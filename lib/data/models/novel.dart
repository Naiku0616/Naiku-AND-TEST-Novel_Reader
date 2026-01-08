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
  final int currentPage;
  final int totalPages;
  final int coverColor;

  const Novel({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.createdAt,
    required this.lastReadAt,
    required this.totalChapters,
    this.currentPage = 0,
    this.totalPages = 0,
    this.coverColor = 0,
  });

  factory Novel.create({
    required String title,
    required String author,
    required String filePath,
  }) {
    final now = DateTime.now();
    return Novel(
      id: const Uuid().v4(),
      title: title,
      author: author,
      filePath: filePath,
      createdAt: now,
      lastReadAt: now,
      totalChapters: 0,
    );
  }

  Novel copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    DateTime? createdAt,
    DateTime? lastReadAt,
    int? totalChapters,
    int? currentPage,
    int? totalPages,
    int? coverColor,
  }) {
    return Novel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      totalChapters: totalChapters ?? this.totalChapters,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      coverColor: coverColor ?? this.coverColor,
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
      'currentPage': currentPage,
      'totalPages': totalPages,
      'coverColor': coverColor,
    };
  }

  factory Novel.fromMap(Map<String, dynamic> map) {
    return Novel(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      filePath: map['filePath'],
      createdAt: DateTime.parse(map['createdAt']),
      lastReadAt: DateTime.parse(map['lastReadAt']),
      totalChapters: map['totalChapters'],
      currentPage: map['currentPage'] ?? 0,
      totalPages: map['totalPages'] ?? 0,
      coverColor: map['coverColor'] ?? 0,
    );
  }
}

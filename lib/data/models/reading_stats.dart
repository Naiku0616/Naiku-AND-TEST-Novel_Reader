class ReadingStats {
  final String novelId;
  final int totalPagesRead;
  final int totalReadingTime;
  final DateTime firstReadAt;
  final DateTime lastReadAt;
  final int readingSessions;

  const ReadingStats({
    required this.novelId,
    required this.totalPagesRead,
    required this.totalReadingTime,
    required this.firstReadAt,
    required this.lastReadAt,
    required this.readingSessions,
  });

  factory ReadingStats.create({
    required String novelId,
  }) {
    final now = DateTime.now();
    return ReadingStats(
      novelId: novelId,
      totalPagesRead: 0,
      totalReadingTime: 0,
      firstReadAt: now,
      lastReadAt: now,
      readingSessions: 0,
    );
  }

  ReadingStats copyWith({
    String? novelId,
    int? totalPagesRead,
    int? totalReadingTime,
    DateTime? firstReadAt,
    DateTime? lastReadAt,
    int? readingSessions,
  }) {
    return ReadingStats(
      novelId: novelId ?? this.novelId,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
      firstReadAt: firstReadAt ?? this.firstReadAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingSessions: readingSessions ?? this.readingSessions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'novelId': novelId,
      'totalPagesRead': totalPagesRead,
      'totalReadingTime': totalReadingTime,
      'firstReadAt': firstReadAt.toIso8601String(),
      'lastReadAt': lastReadAt.toIso8601String(),
      'readingSessions': readingSessions,
    };
  }

  factory ReadingStats.fromMap(Map<String, dynamic> map) {
    return ReadingStats(
      novelId: map['novelId'],
      totalPagesRead: map['totalPagesRead'] ?? 0,
      totalReadingTime: map['totalReadingTime'] ?? 0,
      firstReadAt: DateTime.parse(map['firstReadAt']),
      lastReadAt: DateTime.parse(map['lastReadAt']),
      readingSessions: map['readingSessions'] ?? 0,
    );
  }

  double get averageReadingTimePerSession {
    return readingSessions > 0 ? totalReadingTime / readingSessions : 0;
  }

  double get averagePagesPerMinute {
    final totalMinutes = totalReadingTime / 60;
    return totalMinutes > 0 ? totalPagesRead / totalMinutes : 0;
  }

  int get daysSinceFirstRead {
    return DateTime.now().difference(firstReadAt).inDays;
  }
}

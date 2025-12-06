class Chapter {
  final String id;
  final String novelId;
  final String title;
  final int chapterNumber;
  final String content;
  final int wordCount;

  Chapter({
    required this.id,
    required this.novelId,
    required this.title,
    required this.chapterNumber,
    required this.content,
    required this.wordCount,
  });

  factory Chapter.create({
    required String novelId,
    required String title,
    required String content,
    required int chapterNumber,
  }) {
    return Chapter(
      id: '$novelId-chapter-$chapterNumber',
      novelId: novelId,
      title: title,
      chapterNumber: chapterNumber,
      content: content,
      wordCount: content.length,
    );
  }
}

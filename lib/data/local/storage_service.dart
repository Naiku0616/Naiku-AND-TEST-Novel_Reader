import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/novel.dart';
import '../models/bookmark.dart';
import '../models/reading_stats.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _novelsKey = 'novels';
  static const String _bookmarksKey = 'bookmarks';
  static const String _readingStatsKey = 'reading_stats';
  static const String _readerSettingsKey = 'reader_settings';
  List<Novel>? _novelsCache;
  DateTime? _lastCacheTime;
  Map<String, List<Bookmark>>? _bookmarksCache;
  Map<String, ReadingStats>? _readingStatsCache;
  Map<String, dynamic>? _readerSettingsCache;

  Future<void> saveNovel(Novel novel) async {
    final prefs = await SharedPreferences.getInstance();
    final novels = await getAllNovels();

    // 移除旧的（如果存在）
    novels.removeWhere((n) => n.id == novel.id);
    novels.add(novel);

    final novelsJson = novels.map((n) => n.toMap()).toList();
    await prefs.setString(_novelsKey, json.encode(novelsJson));

    // 更新缓存
    _novelsCache = novels;
    _lastCacheTime = DateTime.now();
  }

  Future<List<Novel>> getAllNovels() async {
    // 如果缓存有效且不超过30秒，直接返回缓存
    if (_novelsCache != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!).inSeconds < 30) {
      return _novelsCache!;
    }

    final prefs = await SharedPreferences.getInstance();
    final novelsJson = prefs.getString(_novelsKey);

    if (novelsJson == null) {
      _novelsCache = [];
      _lastCacheTime = DateTime.now();
      return [];
    }

    try {
      final List<dynamic> parsed = json.decode(novelsJson);
      _novelsCache = parsed.map((map) => Novel.fromMap(map)).toList();
      _lastCacheTime = DateTime.now();
      return _novelsCache!;
    } catch (e) {
      _novelsCache = [];
      _lastCacheTime = DateTime.now();
      return [];
    }
  }

  Future<void> deleteNovel(String novelId) async {
    final prefs = await SharedPreferences.getInstance();
    final novels = await getAllNovels();

    novels.removeWhere((n) => n.id == novelId);

    final novelsJson = novels.map((n) => n.toMap()).toList();
    await prefs.setString(_novelsKey, json.encode(novelsJson));

    // 清除缓存
    _novelsCache = null;
  }

  Future<void> updateLastRead(String novelId) async {
    final novels = await getAllNovels();
    final novelIndex = novels.indexWhere((n) => n.id == novelId);

    if (novelIndex != -1) {
      final novel = novels[novelIndex];
      final updatedNovel = novel.copyWith(
        lastReadAt: DateTime.now(),
      );

      novels[novelIndex] = updatedNovel;
      await saveNovels(novels);
    }
  }

  Future<void> saveNovels(List<Novel> novels) async {
    final prefs = await SharedPreferences.getInstance();
    final novelsJson = novels.map((n) => n.toMap()).toList();
    await prefs.setString(_novelsKey, json.encode(novelsJson));

    _novelsCache = novels;
    _lastCacheTime = DateTime.now();
  }

  void clearCache() {
    _novelsCache = null;
  }

  Future<void> saveBookmark(String novelId, Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks(novelId);

    bookmarks.add(bookmark);

    final bookmarksJson = bookmarks.map((b) => b.toMap()).toList();
    await prefs.setString(
        '$_bookmarksKey-$novelId', json.encode(bookmarksJson));

    _bookmarksCache ??= {};
    _bookmarksCache![novelId] = bookmarks;
  }

  Future<List<Bookmark>> getBookmarks(String novelId) async {
    if (_bookmarksCache != null && _bookmarksCache!.containsKey(novelId)) {
      return _bookmarksCache![novelId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString('$_bookmarksKey-$novelId');

    if (bookmarksJson == null) {
      return [];
    }

    try {
      final List<dynamic> parsed = json.decode(bookmarksJson);
      final bookmarks = parsed.map((map) => Bookmark.fromMap(map)).toList();
      _bookmarksCache ??= {};
      _bookmarksCache![novelId] = bookmarks;
      return bookmarks;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteBookmark(String novelId, String bookmarkId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks(novelId);

    bookmarks.removeWhere((b) => b.id == bookmarkId);

    final bookmarksJson = bookmarks.map((b) => b.toMap()).toList();
    await prefs.setString(
        '$_bookmarksKey-$novelId', json.encode(bookmarksJson));

    if (_bookmarksCache != null) {
      _bookmarksCache![novelId] = bookmarks;
    }
  }

  Future<void> updateBookmark(String novelId, Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks(novelId);

    final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index != -1) {
      bookmarks[index] = bookmark;
    }

    final bookmarksJson = bookmarks.map((b) => b.toMap()).toList();
    await prefs.setString(
        '$_bookmarksKey-$novelId', json.encode(bookmarksJson));

    if (_bookmarksCache != null) {
      _bookmarksCache![novelId] = bookmarks;
    }
  }

  void clearBookmarksCache() {
    _bookmarksCache = null;
  }

  Future<void> saveReadingStats(ReadingStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = stats.toMap();
    await prefs.setString(
        '$_readingStatsKey-${stats.novelId}', json.encode(statsJson));

    _readingStatsCache ??= {};
    _readingStatsCache![stats.novelId] = stats;
  }

  Future<ReadingStats?> getReadingStats(String novelId) async {
    if (_readingStatsCache != null &&
        _readingStatsCache!.containsKey(novelId)) {
      return _readingStatsCache![novelId];
    }

    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('$_readingStatsKey-$novelId');

    if (statsJson == null) {
      return null;
    }

    try {
      final Map<String, dynamic> parsed = json.decode(statsJson);
      final stats = ReadingStats.fromMap(parsed);
      _readingStatsCache ??= {};
      _readingStatsCache![novelId] = stats;
      return stats;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateReadingStats(String novelId,
      {int? pagesRead, int? readingTime}) async {
    final stats =
        await getReadingStats(novelId) ?? ReadingStats.create(novelId: novelId);

    final updatedStats = stats.copyWith(
      totalPagesRead: (stats.totalPagesRead + (pagesRead ?? 0)),
      totalReadingTime: (stats.totalReadingTime + (readingTime ?? 0)),
      lastReadAt: DateTime.now(),
      readingSessions: stats.readingSessions + 1,
    );

    await saveReadingStats(updatedStats);
  }

  Future<void> deleteReadingStats(String novelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_readingStatsKey-$novelId');

    if (_readingStatsCache != null) {
      _readingStatsCache!.remove(novelId);
    }
  }

  void clearReadingStatsCache() {
    _readingStatsCache = null;
  }

  Future<SharedPreferences> getPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> saveReaderSettings({
    required double fontSize,
    required double lineHeight,
    required String fontFamily,
    required String themeMode,
    required String pageTurnMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'fontFamily': fontFamily,
      'themeMode': themeMode,
      'pageTurnMode': pageTurnMode,
    };
    await prefs.setString(_readerSettingsKey, json.encode(settings));
    _readerSettingsCache = settings;
  }

  Future<Map<String, dynamic>?> getReaderSettings() async {
    if (_readerSettingsCache != null) {
      return _readerSettingsCache;
    }

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_readerSettingsKey);

    if (settingsJson == null) {
      return null;
    }

    try {
      final Map<String, dynamic> parsed = json.decode(settingsJson);
      _readerSettingsCache = parsed;
      return parsed;
    } catch (e) {
      return null;
    }
  }

  void clearReaderSettingsCache() {
    _readerSettingsCache = null;
  }
}

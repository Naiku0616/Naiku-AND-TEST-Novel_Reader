import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/novel.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _novelsKey = 'novels';
  List<Novel>? _novelsCache; // 添加内存缓存
  DateTime? _lastCacheTime;

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
      final updatedNovel = Novel(
        id: novel.id,
        title: novel.title,
        author: novel.author,
        filePath: novel.filePath,
        createdAt: novel.createdAt,
        lastReadAt: DateTime.now(),
        totalChapters: novel.totalChapters,
      );

      novels[novelIndex] = updatedNovel;
      await saveNovels(novels);
    }
  }

  Future<void> saveNovels(List<Novel> novels) async {
    final prefs = await SharedPreferences.getInstance();
    final novelsJson = novels.map((n) => n.toMap()).toList();
    await prefs.setString(_novelsKey, json.encode(novelsJson));

    // 更新缓存
    _novelsCache = novels;
    _lastCacheTime = DateTime.now();
  }

  // 清理缓存
  void clearCache() {
    _novelsCache = null;
  }
}

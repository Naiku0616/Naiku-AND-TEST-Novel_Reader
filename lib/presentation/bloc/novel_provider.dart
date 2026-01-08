import 'package:flutter/material.dart';
import 'package:novel_reader/data/models/novel.dart';
import 'package:novel_reader/data/local/storage_service.dart';

class NovelProvider extends ChangeNotifier {
  List<Novel> _novels = [];
  bool _isLoading = false;
  String? _error;

  List<Novel> get novels => _novels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NovelProvider() {
    _loadNovels();
  }

  Future<void> _loadNovels() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _novels = await StorageService().getAllNovels();
    } catch (e) {
      _error = e.toString();
      debugPrint('加载小说失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNovels() async {
    StorageService().clearCache(); // 清除缓存
    await _loadNovels();
  }

  Future<void> addNovel(Novel novel) async {
    try {
      await StorageService().saveNovel(novel);
      // 直接添加到列表，避免重新加载
      _novels.add(novel);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteNovel(String novelId) async {
    try {
      await StorageService().deleteNovel(novelId);
      _novels.removeWhere((n) => n.id == novelId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateNovelLastRead(String novelId) async {
    try {
      await StorageService().updateLastRead(novelId);
      final index = _novels.indexWhere((n) => n.id == novelId);
      if (index != -1) {
        final novel = _novels[index];
        final updatedNovel = novel.copyWith(
          lastReadAt: DateTime.now(),
        );
        _novels[index] = updatedNovel;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('更新阅读时间失败: $e');
    }
  }

  Future<void> updateNovelProgress(Novel updatedNovel) async {
    try {
      await StorageService().saveNovel(updatedNovel);
      final index = _novels.indexWhere((n) => n.id == updatedNovel.id);
      if (index != -1) {
        _novels[index] = updatedNovel;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('更新阅读进度失败: $e');
    }
  }
}

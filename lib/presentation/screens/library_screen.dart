// lib/presentation/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:novel_reader/data/models/novel.dart';
import 'package:novel_reader/presentation/bloc/novel_provider.dart';
import 'package:novel_reader/presentation/bloc/theme_provider.dart';
import 'package:novel_reader/core/services/novel_importer.dart';
import 'package:novel_reader/data/local/storage_service.dart';
import 'package:novel_reader/presentation/screens/reader_screen.dart';
import 'package:novel_reader/presentation/widgets/novel_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.lastRead;
  bool _isGridView = true;
  bool _showAdvancedSearch = false;
  int? _minProgress;
  int? _maxProgress;
  DateTime? _startDate;
  DateTime? _endDate;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          '我的书架',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 24,
            onPressed: () => _importNovel(context),
            tooltip: '导入小说',
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 24,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode ? '浅色模式' : '深色模式',
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.grid_view : Icons.list),
            iconSize: 24,
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
            tooltip: _isGridView ? '列表视图' : '网格视图',
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onSelected: (option) {
              setState(() => _sortOption = option);
            },
            tooltip: '排序',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.lastRead,
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 12),
                    Text('最近阅读', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOption.title,
                child: Row(
                  children: [
                    Icon(Icons.title, size: 20),
                    SizedBox(width: 12),
                    Text('书名', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOption.author,
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('作者', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOption.createTime,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 12),
                    Text('创建时间', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              _searchFocusNode.unfocus();
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: _searchFocusNode,
                              onTap: () {
                                _searchFocusNode.requestFocus();
                              },
                              decoration: InputDecoration(
                                hintText: '搜索书名或作者...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchQuery.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        _showAdvancedSearch
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                      ),
                                      onPressed: () {
                                        setState(() => _showAdvancedSearch =
                                            !_showAdvancedSearch);
                                      },
                                      tooltip: '高级搜索',
                                    ),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_showAdvancedSearch) _buildAdvancedSearch(),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<NovelProvider>(
                    builder: (context, novelProvider, child) {
                      if (novelProvider.isLoading &&
                          novelProvider.novels.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (novelProvider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text('加载失败: ${novelProvider.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => novelProvider.refreshNovels(),
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        );
                      }

                      final filteredNovels =
                          _filterAndSortNovels(novelProvider.novels);

                      if (filteredNovels.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _searchQuery.isEmpty ? '书架空空如也' : '没有找到匹配的小说',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_searchQuery.isEmpty)
                                const Text(
                                  '点击右上角按钮导入小说',
                                  style: TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                        );
                      }

                      return _isGridView
                          ? _buildGridView(filteredNovels)
                          : _buildListView(filteredNovels);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Novel> _filterAndSortNovels(List<Novel> novels) {
    var filtered = novels;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((novel) =>
              novel.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              novel.author.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_minProgress != null || _maxProgress != null) {
      filtered = filtered.where((novel) {
        if (novel.totalPages == 0) return false;
        final progress = (novel.currentPage / novel.totalPages * 100).round();
        if (_minProgress != null && progress < _minProgress!) return false;
        if (_maxProgress != null && progress > _maxProgress!) return false;
        return true;
      }).toList();
    }

    if (_startDate != null) {
      filtered = filtered
          .where((novel) => novel.createdAt.isAfter(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      filtered = filtered
          .where((novel) => novel.createdAt.isBefore(_endDate!))
          .toList();
    }

    switch (_sortOption) {
      case SortOption.lastRead:
        filtered.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
        break;
      case SortOption.title:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.author:
        filtered.sort((a, b) => a.author.compareTo(b.author));
        break;
      case SortOption.createTime:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  Widget _buildGridView(List<Novel> novels) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];
        return NovelCard(
          novel: novel,
          onTap: () => _openNovel(context, novel),
          onDelete: () => _deleteNovel(context, novel.id),
          onExport: () => _exportNovel(context, novel),
          isGridView: true,
        );
      },
    );
  }

  Widget _buildListView(List<Novel> novels) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NovelCard(
            novel: novel,
            onTap: () => _openNovel(context, novel),
            onDelete: () => _deleteNovel(context, novel.id),
            onExport: () => _exportNovel(context, novel),
            isGridView: false,
          ),
        );
      },
    );
  }

  Future<void> _importNovel(BuildContext context) async {
    final importer = NovelImporter();
    final novel = await importer.importNovel();

    if (!context.mounted) return;

    if (novel != null) {
      final provider = Provider.of<NovelProvider>(context, listen: false);
      await provider.addNovel(novel);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功导入《${novel.title}》'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该文件已导入，无需重复导入'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openNovel(BuildContext context, Novel novel) async {
    final provider = Provider.of<NovelProvider>(context, listen: false);
    await provider.updateNovelLastRead(novel.id);

    final novels = await StorageService().getAllNovels();
    final latestNovel = novels.firstWhere((n) => n.id == novel.id);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(novel: latestNovel),
      ),
    );
  }

  Future<void> _deleteNovel(BuildContext context, String novelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除小说'),
        content: const Text('确定要删除这本小说吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // 修复3：在异步对话框操作后检查上下文
    if (!context.mounted) return;

    if (confirmed == true) {
      final provider = Provider.of<NovelProvider>(context, listen: false);
      try {
        await provider.deleteNovel(novelId);

        // 修复4：在删除操作后检查上下文
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!context.mounted) return; // 修复5：在错误处理中检查上下文

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _exportNovel(BuildContext context, Novel novel) async {
    try {
      final importer = NovelImporter();
      final success = await importer.exportNovel(novel);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导出《${novel.title}》'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导出失败'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAdvancedSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('阅读进度：'),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '最小 %',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _minProgress = value.isEmpty ? null : int.tryParse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('-'),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '最大 %',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _maxProgress = value.isEmpty ? null : int.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('创建时间：'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, isStart: true),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _startDate == null
                        ? '开始日期'
                        : '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('-'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, isStart: false),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _endDate == null
                        ? '结束日期'
                        : '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _minProgress = null;
                _maxProgress = null;
                _startDate = null;
                _endDate = null;
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重置筛选'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}

enum SortOption {
  lastRead,
  title,
  author,
  createTime,
}

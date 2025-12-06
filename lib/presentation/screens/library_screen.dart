// lib/presentation/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:novel_reader/data/models/novel.dart';
import 'package:novel_reader/presentation/bloc/novel_provider.dart';
import 'package:novel_reader/core/services/novel_importer.dart';
import 'package:novel_reader/presentation/screens/reader_screen.dart';
import 'package:novel_reader/presentation/widgets/novel_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的书架',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _importNovel(context),
            tooltip: '导入小说',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NovelProvider>(context, listen: false)
                  .refreshNovels();
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<NovelProvider>(
        builder: (context, novelProvider, child) {
          if (novelProvider.isLoading && novelProvider.novels.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (novelProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
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

          if (novelProvider.novels.isEmpty) {
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
                  const Text(
                    '书架空空如也',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '点击右上角按钮导入小说',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: novelProvider.novels.length,
            itemBuilder: (context, index) {
              final novel = novelProvider.novels[index];
              return NovelCard(
                novel: novel,
                onTap: () => _openNovel(context, novel),
                onDelete: () => _deleteNovel(context, novel.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _importNovel(BuildContext context) async {
    final importer = NovelImporter();
    final novel = await importer.importNovel();

    // 修复1：在第一个异步操作后检查上下文
    if (!context.mounted) return;

    if (novel != null) {
      final provider = Provider.of<NovelProvider>(context, listen: false);
      await provider.addNovel(novel);

      // 修复2：在第二个异步操作后再次检查上下文
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功导入《${novel.title}》'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openNovel(BuildContext context, Novel novel) {
    Provider.of<NovelProvider>(context, listen: false)
        .updateNovelLastRead(novel.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(novel: novel),
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
            duration: const Duration(seconds: 2),
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
}

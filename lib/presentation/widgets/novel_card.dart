import 'package:flutter/material.dart';
import 'package:novel_reader/data/models/novel.dart';

class NovelCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onExport;
  final bool isGridView;

  const NovelCard({
    super.key,
    required this.novel,
    required this.onTap,
    required this.onDelete,
    this.onExport,
    this.isGridView = true,
  });

  @override
  Widget build(BuildContext context) {
    final coverColor = Color(novel.coverColor);

    if (!isGridView) {
      return _buildListView(context, coverColor);
    }

    return _buildGridView(context, coverColor);
  }

  Widget _buildGridView(BuildContext context, Color coverColor) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          coverColor,
                          coverColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 52,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              novel.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              novel.author,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            if (novel.totalPages > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: novel.totalPages > 0
                                              ? (novel.currentPage + 1) /
                                                  novel.totalPages
                                              : 0.0,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            coverColor,
                                          ),
                                          minHeight: 3,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${((novel.currentPage + 1) / novel.totalPages * 100).round()}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${novel.currentPage + 1}/${novel.totalPages}页',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Text(
                          _formatDate(novel.lastReadAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 5,
              right: 5,
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                color: Colors.white,
                itemBuilder: (context) => [
                  if (onExport != null)
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('导出小说'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除小说'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info),
                        SizedBox(width: 8),
                        Text('查看详情'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else if (value == 'details') {
                    _showNovelDetails(context);
                  } else if (value == 'export' && onExport != null) {
                    onExport!();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, Color coverColor) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Row(
          children: [
            Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    coverColor,
                    coverColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.menu_book,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          novel.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          novel.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (novel.totalPages > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: novel.totalPages > 0
                                          ? (novel.currentPage + 1) /
                                              novel.totalPages
                                          : 0.0,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        coverColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${((novel.currentPage + 1) / novel.totalPages * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${novel.currentPage + 1}/${novel.totalPages}页',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Text(
                      _formatDate(novel.lastReadAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey[600],
              ),
              itemBuilder: (context) => [
                if (onExport != null)
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('导出小说'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除小说'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info),
                      SizedBox(width: 8),
                      Text('查看详情'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                } else if (value == 'details') {
                  _showNovelDetails(context);
                } else if (value == 'export' && onExport != null) {
                  onExport!();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  void _showNovelDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(novel.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('作者：${novel.author}'),
              const SizedBox(height: 8),
              Text('创建时间：${_formatFullDate(novel.createdAt)}'),
              const SizedBox(height: 8),
              Text('最后阅读：${_formatFullDate(novel.lastReadAt)}'),
              const SizedBox(height: 8),
              Text('文件路径：${novel.filePath}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

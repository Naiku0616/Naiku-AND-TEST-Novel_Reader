// lib/presentation/screens/reader_screen.dart
import 'package:flutter/material.dart';
import 'package:novel_reader/data/models/novel.dart';
import 'package:novel_reader/core/services/novel_importer.dart';

class ReaderScreen extends StatefulWidget {
  final Novel novel;
  const ReaderScreen({super.key, required this.novel});
  @override
  ReaderScreenState createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> {
  // ---------- 状态管理 ----------
  String _content = '';
  double _fontSize = 18.0;
  bool _isDarkMode = false;
  Color _backgroundColor = Colors.grey[100]!;
  bool _showSettings = false;
  final NovelImporter _importer = NovelImporter();

  // ---------- 分页相关状态 (性能优化核心) ----------
  List<String> _pages = []; // 存储分页后的内容
  int _currentPage = 0; // 当前页码
  bool _isLoading = true; // 加载状态
  final int _charsPerPage = 1500; // 每页字符数（可根据屏幕调整）
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadContent(); // 初始化加载内容
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 释放滚动控制器，防止内存泄漏
    super.dispose();
  }

  // ---------- 核心方法：智能分页加载 ----------
  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    final fullContent = await _importer.readNovelContent(widget.novel.filePath);

    if (!mounted) return; // 防止在组件卸载后更新状态

    // 优化策略：小文件直接显示，大文件才分页
    if (fullContent.length <= _charsPerPage * 3) {
      // 例如小于3页
      setState(() {
        _content = fullContent;
        _pages = [fullContent]; // 当作一页处理
        _isLoading = false;
      });
    } else {
      // 大文件执行分页算法
      await _paginateContent(fullContent);
    }
  }

  // 分页算法：处理UTF-8字符边界，防止乱码
  Future<void> _paginateContent(String fullContent) async {
    final pages = <String>[];
    int startIndex = 0;

    while (startIndex < fullContent.length) {
      int endIndex = startIndex + _charsPerPage;
      // 防止最后一页越界
      if (endIndex > fullContent.length) endIndex = fullContent.length;
      // 获取本页内容
      String page = fullContent.substring(startIndex, endIndex);
      pages.add(page);
      startIndex = endIndex; // 移动到下一页的起始位置
    }

    if (mounted) {
      setState(() {
        _pages = pages;
        _isLoading = false;
        _content = _pages.isNotEmpty ? _pages[0] : ''; // 默认显示第一页
      });
    }
  }

  // ---------- 页面构建 ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. 修复：添加AppBar，解决返回书架问题
      appBar: _showSettings ? null : _buildAppBar(),
      backgroundColor: _isDarkMode ? Colors.black : _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 2. 修复：设置面板独立显示，不占用导航空间
            if (_showSettings) _buildSettingsPanel(),
            // 阅读内容区域
            Expanded(child: _buildReaderContent()),
          ],
        ),
      ),
    );
  }

  // 构建顶部导航栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: _isDarkMode ? Colors.white : Colors.black),
        onPressed: () => Navigator.pop(context),
        tooltip: '返回书架',
      ),
      title: Text(
        widget.novel.title,
        style: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.black,
          fontSize: 16.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      elevation: 0,
    );
  }

  // 构建阅读器内容
  Widget _buildReaderContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. 修复：使用GestureDetector包裹，确保点击有效
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSettings = !_showSettings;
        });
      },
      behavior: HitTestBehavior.opaque, // 关键：确保空白区域可点击
      child: _pages.length <= 1
          ? _buildSinglePageView() // 单页（小文件）模式
          : _buildPagedView(), // 多页（大文件）模式
    );
  }

  // 单页视图（用于小文件，保持原有简单滚动）
  Widget _buildSinglePageView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SelectableText(
          // 使用SelectableText支持文本选择
          _content,
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.8,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // 多页视图（用于大文件，解决卡顿核心）
  Widget _buildPagedView() {
    return Column(
      children: [
        // 页面指示器
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${_currentPage + 1}/${_pages.length}',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        // 分页内容区
        Expanded(
          child: PageView.builder(
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _pages[index],
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.8,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 翻页按钮（可选）
        if (_pages.length > 1) _buildPageNavigation(),
      ],
    );
  }

  // 翻页按钮
  Widget _buildPageNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left,
                color: _isDarkMode ? Colors.white : Colors.blue),
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            tooltip: '上一页',
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: _isDarkMode ? Colors.white : Colors.blue),
            onPressed: _currentPage < _pages.length - 1
                ? () => setState(() => _currentPage++)
                : null,
            tooltip: '下一页',
          ),
        ],
      ),
    );
  }

  // ---------- 设置面板 (保持不变) ----------
  Widget _buildSettingsPanel() {
    return Container(
      color: _isDarkMode ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.text_decrease,
                    color: _isDarkMode ? Colors.white : Colors.black),
                onPressed: () => setState(
                    () => _fontSize = (_fontSize > 14) ? _fontSize - 1 : 14),
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 14,
                  max: 28,
                  onChanged: (value) => setState(() => _fontSize = value),
                ),
              ),
              IconButton(
                icon: Icon(Icons.text_increase,
                    color: _isDarkMode ? Colors.white : Colors.black),
                onPressed: () => setState(
                    () => _fontSize = (_fontSize < 28) ? _fontSize + 1 : 28),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorOption(Colors.grey[100]!, '浅灰'),
              _buildColorOption(Colors.brown[50]!, '米黄'),
              _buildColorOption(Colors.blueGrey[50]!, '青灰'),
              _buildColorOption(Colors.green[50]!, '浅绿'),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text('夜间模式',
                style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black)),
            value: _isDarkMode,
            onChanged: (value) => setState(() => _isDarkMode = value),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, String label) {
    return GestureDetector(
      onTap: () => setState(() {
        _backgroundColor = color;
        _isDarkMode = false;
      }),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _backgroundColor == color
                    ? Colors.blue
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

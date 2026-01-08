import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:novel_reader/data/models/novel.dart';
import 'package:novel_reader/data/models/bookmark.dart';
import 'package:novel_reader/core/services/novel_importer.dart';
import 'package:novel_reader/data/local/storage_service.dart';
import 'package:novel_reader/presentation/bloc/novel_provider.dart';

class ReaderScreen extends StatefulWidget {
  final Novel novel;
  const ReaderScreen({super.key, required this.novel});

  @override
  ReaderScreenState createState() => ReaderScreenState();
}

class _ReaderConstants {
  static const int charsPerPage = 1500;
  static const double defaultFontSize = 16.0;
  static const double defaultLineHeight = 1.6;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.2;
  static const double minAutoReadSpeed = 1.0;
  static const double maxAutoReadSpeed = 10.0;
  static const double tapZoneLeftRatio = 0.3;
  static const double tapZoneRightRatio = 0.7;
  static const double tapZoneTopRatio = 0.2;
  static const double tapZoneBottomRatio = 0.8;
  static const double pagePaddingHorizontal = 20.0;
  static const double pagePaddingTop = 12.0;
  static const double pagePaddingBottom = 20.0;
  static const double singlePagePaddingTop = 20.0;
  static const double topBarHeight = 44.0;
  static const double bottomBarHeight = 44.0;
  static const int pageChangeDuration = 300;
  static const int lineHeightDivisions = 10;
  static const int autoReadSpeedDivisions = 9;
}

class ReaderScreenState extends State<ReaderScreen> {
  String _content = '';
  double _fontSize = _ReaderConstants.defaultFontSize;
  double _lineHeight = _ReaderConstants.defaultLineHeight;
  String _fontFamily = 'System';
  bool _showSettings = false;
  bool _showMenu = false;
  Timer? _autoPageTimer;
  final NovelImporter _importer = NovelImporter();

  List<String> _pages = [];
  int _currentPage = 0;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  late Novel _currentNovel;
  List<Bookmark> _bookmarks = [];
  bool _isBookmarked = false;
  String _fullContent = '';

  final List<String> _fontOptions = ['System', 'Serif', 'Monospace', 'Cursive'];
  String _pageTurnMode = 'swipe';
  bool _isAutoReading = false;
  double _autoReadSpeed = 5.0;

  String _themeMode = 'light';
  final Map<String, ReaderTheme> _themes = {
    'light': ReaderTheme(
      name: '日间',
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      secondaryColor: Colors.grey[600]!,
      iconColor: Colors.black54,
      brightness: 1.0,
    ),
    'dark': ReaderTheme(
      name: '夜间',
      backgroundColor: const Color(0xFF1A1A1A),
      textColor: Colors.white,
      secondaryColor: Colors.grey[400]!,
      iconColor: Colors.white70,
      brightness: 0.3,
    ),
    'eye': ReaderTheme(
      name: '护眼',
      backgroundColor: const Color(0xFFC7EDCC),
      textColor: const Color(0xFF1A3A1B),
      secondaryColor: const Color(0xFF3D6A3E),
      iconColor: const Color(0xFF1A3A1B),
      brightness: 1.0,
    ),
    'sepia': ReaderTheme(
      name: '羊皮',
      backgroundColor: const Color(0xFFF4ECD8),
      textColor: const Color(0xFF3D2E22),
      secondaryColor: const Color(0xFF6B5A4A),
      iconColor: const Color(0xFF3D2E22),
      brightness: 1.0,
    ),
  };

  @override
  void initState() {
    super.initState();
    _currentNovel = widget.novel;
    _loadReaderSettings();
    _loadContent();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _stopAutoReading();
    _scrollController.dispose();
    _pageController.dispose();
    _autoPageTimer?.cancel();
    super.dispose();
  }

  void _startAutoReading() {
    if (_isAutoReading) return;

    setState(() => _isAutoReading = true);
    _autoPageTimer = Timer.periodic(
      Duration(milliseconds: (10000 / _autoReadSpeed).round()),
      (timer) {
        if (_currentPage < _pages.length - 1) {
          _nextPage();
        } else {
          _stopAutoReading();
        }
      },
    );
  }

  void _stopAutoReading() {
    if (!_isAutoReading) return;

    _autoPageTimer?.cancel();
    setState(() => _isAutoReading = false);
  }

  void _toggleAutoReading() {
    if (_isAutoReading) {
      _stopAutoReading();
    } else {
      _startAutoReading();
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await StorageService().getBookmarks(widget.novel.id);
    final isBookmarked = bookmarks.any((b) => b.pageNumber == _currentPage);
    setState(() {
      _bookmarks = bookmarks;
      _isBookmarked = isBookmarked;
    });
  }

  void _checkBookmarkStatus() {
    _isBookmarked = _bookmarks.any((b) => b.pageNumber == _currentPage);
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await _removeBookmark();
    } else {
      await _addBookmark();
    }
  }

  Future<void> _addBookmark() async {
    final bookmark = Bookmark.create(
      pageNumber: _currentPage,
    );
    await StorageService().saveBookmark(widget.novel.id, bookmark);
    setState(() {
      _bookmarks.add(bookmark);
      _isBookmarked = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加书签:第 ${_currentPage + 1} 页')),
      );
    }
  }

  Future<void> _removeBookmark() async {
    final bookmark = _bookmarks.firstWhere(
      (b) => b.pageNumber == _currentPage,
    );
    await StorageService().deleteBookmark(widget.novel.id, bookmark.id);
    setState(() {
      _bookmarks.remove(bookmark);
      _isBookmarked = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已移除书签')),
      );
    }
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('书签列表'),
        content: _bookmarks.isEmpty
            ? const Text('暂无书签')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = _bookmarks[index];
                  return ListTile(
                    title: Text('第 ${bookmark.pageNumber + 1} 页'),
                    subtitle: Text(
                      '添加于 ${_formatDate(bookmark.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: dialogContext,
                          builder: (confirmContext) => AlertDialog(
                            title: const Text('删除书签'),
                            content: const Text('确定要删除这个书签吗?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(confirmContext, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(confirmContext, true),
                                child: const Text('删除',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await StorageService().deleteBookmark(
                            widget.novel.id,
                            bookmark.id,
                          );
                          if (dialogContext.mounted) {
                            setState(() {
                              _bookmarks.removeAt(index);
                              _checkBookmarkStatus();
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('书签已删除')),
                              );
                            }
                          }
                        }
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _currentPage = bookmark.pageNumber;
                      });
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(_currentPage);
                      }
                      Navigator.pop(dialogContext);
                      _saveReadingProgress();
                    },
                  );
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    final fullContent = await _importer.readNovelContent(widget.novel.filePath);

    if (!mounted) return;

    _fullContent = fullContent;

    if (fullContent.length <= _ReaderConstants.charsPerPage * 3) {
      setState(() {
        _content = fullContent;
        _pages = [fullContent];
        _isLoading = false;
      });
    } else {
      await _paginateContent(fullContent);
    }
  }

  Future<void> _repaginateContent() async {
    if (_fullContent.isEmpty) return;

    if (_fullContent.length <= _ReaderConstants.charsPerPage * 3) {
      setState(() {
        _content = _fullContent;
        _pages = [_fullContent];
        _currentPage = 0;
      });
    } else {
      await _paginateContent(_fullContent);
    }
  }

  Future<void> _paginateContent(String fullContent) async {
    final pages = <String>[];
    int startIndex = 0;

    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight -
        _ReaderConstants.pagePaddingTop -
        _ReaderConstants.pagePaddingBottom;

    final lineHeight = _fontSize * _lineHeight;
    final linesPerPage = (availableHeight / lineHeight).floor();

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth =
        screenWidth - _ReaderConstants.pagePaddingHorizontal * 2;
    final charsPerLine = (availableWidth / (_fontSize * 0.6)).floor();

    final charsPerPage = (linesPerPage * charsPerLine * 0.9).floor();

    while (startIndex < fullContent.length) {
      int endIndex = startIndex + charsPerPage;
      if (endIndex > fullContent.length) endIndex = fullContent.length;

      String page = fullContent.substring(startIndex, endIndex);

      if (endIndex < fullContent.length) {
        final lastSentenceEnd = _findLastSentenceEnd(page);
        if (lastSentenceEnd > 0 && lastSentenceEnd < page.length) {
          page = page.substring(0, lastSentenceEnd + 1);
          startIndex += lastSentenceEnd + 1;
        } else {
          startIndex = endIndex;
        }
      } else {
        startIndex = endIndex;
      }

      pages.add(page.trim());
    }

    if (mounted) {
      setState(() {
        _pages = pages;
        _currentPage = _currentNovel.currentPage.clamp(0, pages.length - 1);
        _isLoading = false;
        _content = _pages.isNotEmpty ? _pages[_currentPage] : '';
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(
                milliseconds: _ReaderConstants.pageChangeDuration),
            curve: Curves.easeInOut,
          );
        }
      });

      _saveReadingProgress();
    }
  }

  int _findLastSentenceEnd(String text) {
    final sentenceEndings = ['。', '！', '？', '…', '\n', '\r\n'];
    int lastEnd = -1;

    for (final ending in sentenceEndings) {
      final index = text.lastIndexOf(ending);
      if (index > lastEnd) {
        lastEnd = index;
      }
    }

    if (lastEnd == -1) {
      final commaIndex = text.lastIndexOf('，');
      if (commaIndex > 0 && commaIndex > text.length * 0.8) {
        lastEnd = commaIndex;
      }
    }

    return lastEnd;
  }

  Future<void> _saveReadingProgress() async {
    final updatedNovel = _currentNovel.copyWith(
      currentPage: _currentPage,
      totalPages: _pages.length,
      lastReadAt: DateTime.now(),
    );

    final provider = Provider.of<NovelProvider>(context, listen: false);
    await provider.updateNovelProgress(updatedNovel);

    setState(() {
      _currentNovel = updatedNovel;
    });
  }

  Future<void> _loadReaderSettings() async {
    final settings = await StorageService().getReaderSettings();
    if (settings != null) {
      setState(() {
        _fontSize = settings['fontSize'] ?? _ReaderConstants.defaultFontSize;
        _lineHeight =
            settings['lineHeight'] ?? _ReaderConstants.defaultLineHeight;
        _fontFamily = settings['fontFamily'] ?? 'System';
        _themeMode = settings['themeMode'] ?? 'light';
        _pageTurnMode = settings['pageTurnMode'] ?? 'swipe';
      });
    }
  }

  Future<void> _saveReaderSettings() async {
    await StorageService().saveReaderSettings(
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      fontFamily: _fontFamily,
      themeMode: _themeMode,
      pageTurnMode: _pageTurnMode,
    );
  }

  ReaderTheme get _currentTheme => _themes[_themeMode]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (_showMenu) _buildTopBar(),
                Expanded(child: _buildReaderContent()),
                if (_showMenu) _buildBottomBar(),
              ],
            ),
          ),
          if (_showSettings) _buildSettingsBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _currentTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: _currentTheme.secondaryColor.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTopBarItem(
            icon: Icons.arrow_back_ios,
            label: '',
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentNovel.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _currentTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_currentPage + 1}/${_pages.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _currentTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildTopBarItem(
            icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: '',
            isActive: _isBookmarked,
            onTap: _toggleBookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return _buildBarItem(
      icon: icon,
      label: label,
      isActive: isActive,
      onTap: onTap,
    );
  }

  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return _buildBarItem(
      icon: icon,
      label: label,
      isActive: isActive,
      onTap: onTap,
    );
  }

  Widget _buildBarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: label.isEmpty
            ? Icon(
                icon,
                size: 22,
                color: isActive
                    ? _currentTheme.secondaryColor
                    : _currentTheme.iconColor,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color:
                        isActive ? Colors.deepPurple : _currentTheme.iconColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? Colors.deepPurple
                          : _currentTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _currentTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: _currentTheme.secondaryColor.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarItem(
            icon: _isAutoReading
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            label: '',
            isActive: _isAutoReading,
            onTap: _toggleAutoReading,
          ),
          _buildBottomBarItem(
            icon: Icons.settings_outlined,
            label: '',
            onTap: () {
              setState(() {
                _showSettings = true;
                _showMenu = false;
              });
            },
          ),
          _buildBottomBarItem(
            icon: Icons.format_list_bulleted_outlined,
            label: '',
            onTap: _showBookmarksDialog,
          ),
          _buildBottomBarItem(
            icon: Icons.input_outlined,
            label: '',
            onTap: _showJumpToPageDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildReaderContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: _currentTheme.secondaryColor,
        ),
      );
    }

    return _pages.length <= 1 ? _buildSinglePageView() : _buildPagedView();
  }

  void _handleTap(TapUpDetails details) {
    if (_showSettings) {
      setState(() {
        _showSettings = false;
      });
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    final leftZoneEnd = screenWidth * _ReaderConstants.tapZoneLeftRatio;
    final rightZoneStart = screenWidth * _ReaderConstants.tapZoneRightRatio;
    final topZoneEnd = screenHeight * _ReaderConstants.tapZoneTopRatio;
    final bottomZoneStart = screenHeight * _ReaderConstants.tapZoneBottomRatio;

    if (y < topZoneEnd || y > bottomZoneStart) {
      return;
    }

    if (x < leftZoneEnd) {
      if (_pages.length > 1) {
        _previousPage();
      }
    } else if (x > rightZoneStart) {
      if (_pages.length > 1) {
        _nextPage();
      }
    } else {
      setState(() {
        _showMenu = !_showMenu;
      });

      Future.delayed(const Duration(milliseconds: 50), () {
        if (_pageController.hasClients && _pages.length > 1) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    }
  }

  Widget _buildSinglePageView() {
    final topPadding = _showMenu
        ? _ReaderConstants.singlePagePaddingTop + _ReaderConstants.topBarHeight
        : _ReaderConstants.singlePagePaddingTop;
    final bottomPadding = _showMenu
        ? _ReaderConstants.pagePaddingBottom + _ReaderConstants.bottomBarHeight
        : _ReaderConstants.pagePaddingBottom;

    return Padding(
      padding: EdgeInsets.only(
        left: _ReaderConstants.pagePaddingHorizontal,
        right: _ReaderConstants.pagePaddingHorizontal,
        top: topPadding,
        bottom: bottomPadding,
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SelectionArea(
              child: Text(
                _content,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: _lineHeight,
                  fontFamily: _getFontFamily(),
                  color: _currentTheme.textColor,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _handleTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagedView() {
    return _buildCurrentPageView();
  }

  Widget _buildCurrentPageView() {
    switch (_pageTurnMode) {
      case 'swipe':
        return _buildSwipePagedView();
      case 'tap':
        return _buildTapPagedView();
      case 'scroll':
        return _buildScrollPagedView();
      default:
        return _buildSwipePagedView();
    }
  }

  Widget _buildSwipePagedView() {
    return _buildPagedViewWithPhysics(
      physics: const PageScrollPhysics(),
    );
  }

  Widget _buildTapPagedView() {
    return _buildPagedViewWithPhysics(
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildPagedViewWithPhysics({required ScrollPhysics physics}) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      physics: physics,
      onPageChanged: (index) {
        final isBookmarked = _bookmarks.any((b) => b.pageNumber == index);
        setState(() {
          _currentPage = index;
          _isBookmarked = isBookmarked;
        });
        _saveReadingProgress();
      },
      itemBuilder: (context, index) {
        final topPadding = _showMenu
            ? _ReaderConstants.pagePaddingTop + _ReaderConstants.topBarHeight
            : _ReaderConstants.pagePaddingTop;
        final bottomPadding = _showMenu
            ? _ReaderConstants.pagePaddingBottom +
                _ReaderConstants.bottomBarHeight
            : _ReaderConstants.pagePaddingBottom;

        return Padding(
          padding: EdgeInsets.only(
            left: _ReaderConstants.pagePaddingHorizontal,
            right: _ReaderConstants.pagePaddingHorizontal,
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: Stack(
            children: [
              SelectionArea(
                child: Text(
                  _pages[index],
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: _lineHeight,
                    fontFamily: _getFontFamily(),
                    color: _currentTheme.textColor,
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: _handleTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollPagedView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            final viewportHeight = renderBox.size.height;
            final currentPage =
                (_scrollController.offset / viewportHeight).round();
            if (currentPage >= 0 && currentPage < _pages.length) {
              final isBookmarked =
                  _bookmarks.any((b) => b.pageNumber == currentPage);
              setState(() {
                _currentPage = currentPage;
                _isBookmarked = isBookmarked;
              });
              _saveReadingProgress();
            }
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          final verticalPadding = _showMenu
              ? _ReaderConstants.pagePaddingTop + _ReaderConstants.topBarHeight
              : _ReaderConstants.pagePaddingTop;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _ReaderConstants.pagePaddingHorizontal,
              vertical: verticalPadding,
            ),
            child: Stack(
              children: [
                SelectionArea(
                  child: Text(
                    _pages[index],
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: _lineHeight,
                      fontFamily: _getFontFamily(),
                      color: _currentTheme.textColor,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: _handleTap,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _nextPage() {
    if (_pageTurnMode == 'scroll') {
      if (_currentPage < _pages.length - 1) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final viewportHeight = renderBox.size.height;
          _scrollController.animateTo(
            (_currentPage + 1) * viewportHeight,
            duration: const Duration(
                milliseconds: _ReaderConstants.pageChangeDuration),
            curve: Curves.easeInOut,
          );
        }
      }
    } else {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration:
              const Duration(milliseconds: _ReaderConstants.pageChangeDuration),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    if (_pageTurnMode == 'scroll') {
      if (_currentPage > 0) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final viewportHeight = renderBox.size.height;
          _scrollController.animateTo(
            (_currentPage - 1) * viewportHeight,
            duration: const Duration(
                milliseconds: _ReaderConstants.pageChangeDuration),
            curve: Curves.easeInOut,
          );
        }
      }
    } else {
      if (_currentPage > 0) {
        _pageController.previousPage(
          duration:
              const Duration(milliseconds: _ReaderConstants.pageChangeDuration),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Widget _buildSettingsBottomSheet() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSettings = false;
        });
      },
      child: Container(
        color: Colors.black38,
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: _currentTheme.backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 12),
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _currentTheme.secondaryColor
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildThemeCard(),
                              const SizedBox(height: 12),
                              _buildFontCard(),
                              const SizedBox(height: 12),
                              _buildPageTurnCard(),
                              const SizedBox(height: 12),
                              _buildAutoReadCard(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return _buildSettingCard(
      icon: Icons.palette,
      title: '背景主题',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _themes.entries.map((entry) {
          final isSelected = _themeMode == entry.key;
          return _buildThemeButton(
            theme: entry.value,
            isSelected: isSelected,
            onTap: () {
              if (_themeMode != entry.key) {
                setState(() => _themeMode = entry.key);
                _saveReaderSettings();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontCard() {
    return _buildSettingCard(
      icon: Icons.format_size,
      title: '字体设置',
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.text_fields,
            label: '字体大小',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconButton(
                  icon: Icons.remove,
                  onPressed: () {
                    if (_fontSize > _ReaderConstants.minFontSize) {
                      setState(() => _fontSize = _fontSize - 1);
                      _saveReaderSettings();
                      _repaginateContent();
                    }
                  },
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '${_fontSize.round()}',
                    style: TextStyle(
                      fontSize: 15,
                      color: _currentTheme.textColor,
                    ),
                  ),
                ),
                _buildIconButton(
                  icon: Icons.add,
                  onPressed: () {
                    if (_fontSize < _ReaderConstants.maxFontSize) {
                      setState(() => _fontSize = _fontSize + 1);
                      _saveReaderSettings();
                      _repaginateContent();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingRow(
            icon: Icons.line_weight,
            label: '行间距',
            child: _buildSlider(
              value: _lineHeight,
              min: _ReaderConstants.minLineHeight,
              max: _ReaderConstants.maxLineHeight,
              divisions: _ReaderConstants.lineHeightDivisions,
              onChanged: (value) {
                if (_lineHeight != value) {
                  setState(() => _lineHeight = value);
                  _saveReaderSettings();
                  _repaginateContent();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: false,
            title: Row(
              children: [
                Icon(
                  Icons.font_download,
                  size: 20,
                  color: _currentTheme.iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '字体选择',
                  style: TextStyle(
                    fontSize: 14,
                    color: _currentTheme.textColor,
                  ),
                ),
              ],
            ),
            iconColor: _currentTheme.iconColor,
            collapsedIconColor: _currentTheme.iconColor,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _fontOptions.map((font) {
                    return _buildFontChip(font);
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageTurnCard() {
    return _buildSettingCard(
      icon: Icons.touch_app,
      title: '翻页设置',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _buildPageTurnModeChip('swipe', '滑动'),
          _buildPageTurnModeChip('tap', '点击'),
          _buildPageTurnModeChip('scroll', '滚动'),
        ],
      ),
    );
  }

  Widget _buildAutoReadCard() {
    return _buildSettingCard(
      icon: Icons.speed,
      title: '自动阅读',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${_autoReadSpeed.round()}',
            style: TextStyle(
              fontSize: 15,
              color: _currentTheme.textColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSlider(
              value: _autoReadSpeed,
              min: _ReaderConstants.minAutoReadSpeed,
              max: _ReaderConstants.maxAutoReadSpeed,
              divisions: _ReaderConstants.autoReadSpeedDivisions,
              onChanged: (value) {
                if (_autoReadSpeed != value) {
                  setState(() => _autoReadSpeed = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _currentTheme.secondaryColor.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: _currentTheme.iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _currentTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required ReaderTheme theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 70,
        height: 85,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? _currentTheme.secondaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              color: theme.textColor,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _currentTheme.secondaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: _currentTheme.textColor),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTrackColor: _currentTheme.secondaryColor,
        inactiveTrackColor:
            _currentTheme.secondaryColor.withValues(alpha: 0.15),
        thumbColor: _currentTheme.secondaryColor,
        overlayColor: _currentTheme.secondaryColor.withValues(alpha: 0.1),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPageTurnModeChip(String mode, String label) {
    final isSelected = _pageTurnMode == mode;

    return ChoiceChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _pageTurnMode = mode);
          _saveReaderSettings();
        }
      },
      selectedColor: _currentTheme.secondaryColor.withValues(alpha: 0.2),
      backgroundColor: _currentTheme.secondaryColor.withValues(alpha: 0.08),
      labelStyle: TextStyle(
        color:
            isSelected ? _currentTheme.textColor : _currentTheme.secondaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected
              ? _currentTheme.secondaryColor
              : _currentTheme.secondaryColor.withValues(alpha: 0.15),
          width: isSelected ? 1 : 0.5,
        ),
      ),
      elevation: 0,
    );
  }

  Widget _buildFontChip(String font) {
    final isSelected = _fontFamily == font;

    return ChoiceChip(
      label: Text(
        font,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _fontFamily = font);
          _saveReaderSettings();
        }
      },
      selectedColor: _currentTheme.secondaryColor.withValues(alpha: 0.2),
      backgroundColor: _currentTheme.secondaryColor.withValues(alpha: 0.08),
      labelStyle: TextStyle(
        color:
            isSelected ? _currentTheme.textColor : _currentTheme.secondaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected
              ? _currentTheme.secondaryColor
              : _currentTheme.secondaryColor.withValues(alpha: 0.15),
          width: isSelected ? 1 : 0.5,
        ),
      ),
      elevation: 0,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Icon(
            icon,
            size: 20,
            color: _currentTheme.iconColor,
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _currentTheme.textColor,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  String? _getFontFamily() {
    switch (_fontFamily) {
      case 'Serif':
        return 'serif';
      case 'Monospace':
        return 'monospace';
      case 'Cursive':
        return 'cursive';
      default:
        return null;
    }
  }

  void _showJumpToPageDialog() {
    final TextEditingController pageController = TextEditingController(
      text: (_currentPage + 1).toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('跳转页面'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('总页数:${_pages.length}'),
              const SizedBox(height: 16),
              TextField(
                controller: pageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '页码',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page > 0 && page <= _pages.length) {
                setState(() {
                  _currentPage = page - 1;
                });
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(_currentPage);
                }
                _saveReadingProgress();
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('跳转'),
          ),
        ],
      ),
    );
  }
}

class ReaderTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryColor;
  final Color iconColor;
  final double brightness;

  ReaderTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryColor,
    required this.iconColor,
    required this.brightness,
  });
}

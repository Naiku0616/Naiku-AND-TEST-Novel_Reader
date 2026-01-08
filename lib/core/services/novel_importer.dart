import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:novel_reader/data/models/novel.dart';
import 'package:novel_reader/data/local/storage_service.dart';

class NovelImporter {
  static final Random _random = Random();
  static final List<Color> _coverColors = [
    const Color.fromARGB(255, 108, 92, 231),
    const Color.fromARGB(255, 0, 184, 148),
    const Color.fromARGB(255, 225, 112, 85),
    const Color.fromARGB(255, 9, 132, 227),
    const Color.fromARGB(255, 253, 121, 168),
    const Color.fromARGB(255, 0, 206, 201),
    const Color.fromARGB(255, 99, 110, 114),
    const Color.fromARGB(255, 45, 52, 54),
  ];

  static int _generateRandomCoverColor() {
    return _coverColors[_random.nextInt(_coverColors.length)].toARGB32();
  }

  Future<Novel?> importNovel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path!;

        final existingNovels = await StorageService().getAllNovels();
        StorageService().clearCache();

        final isDuplicate =
            existingNovels.any((novel) => novel.filePath == filePath);

        if (isDuplicate) {
          debugPrint('该文件已导入: $filePath');
          return null;
        }

        final fileContent = await _safeReadFile(filePath);

        final title = _extractTitle(file.name, fileContent);
        final author = _extractAuthor(fileContent);

        final novel = Novel.create(
          title: title,
          author: author,
          filePath: filePath,
        ).copyWith(coverColor: _generateRandomCoverColor());

        await StorageService().saveNovel(novel);

        final updatedNovels = await StorageService().getAllNovels();
        final duplicateCheck =
            updatedNovels.where((n) => n.filePath == filePath).toList();

        if (duplicateCheck.length > 1) {
          debugPrint('检测到重复导入，正在清理...');
          await StorageService().deleteNovel(novel.id);
          return null;
        }

        return novel;
      }
    } catch (e) {
      debugPrint('导入失败: $e');
    }
    return null;
  }

  // 安全的文件读取方法
  Future<String> _safeReadFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();

      // 小文件直接读取
      if (fileSize < 2 * 1024 * 1024) {
        // 2MB以内
        return await file.readAsString();
      }

      // 大文件使用流式读取，避免内存溢出
      return await _streamReadLargeFile(file);
    } catch (e) {
      debugPrint('读取文件失败: $e');
      return '';
    }
  }

  Future<String> _streamReadLargeFile(File file) async {
    final buffer = StringBuffer();
    final lines =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());

    int lineCount = 0;
    const int maxLines = 20000; // 最多读取20000行

    await for (final line in lines) {
      buffer.writeln(line);
      lineCount++;
      if (lineCount >= maxLines) {
        buffer.writeln("\n\n[文件过大，已截断显示]");
        break;
      }
    }

    return buffer.toString();
  }

  String _extractTitle(String fileName, String content) {
    if (content.isEmpty) return fileName.replaceAll('.txt', '');

    // 尝试从内容前50行提取书名
    final lines = content.split('\n').take(50).toList();
    for (var line in lines) {
      line = line.trim();
      if (line.contains('书名') || line.contains('标题') || line.contains('《')) {
        // 清理常见格式
        return line
            .replaceAll('书名：', '')
            .replaceAll('书名:', '')
            .replaceAll('标题：', '')
            .replaceAll('标题:', '')
            .replaceAll('《', '')
            .replaceAll('》', '')
            .trim();
      }
    }

    // 使用文件名
    return fileName.replaceAll('.txt', '');
  }

  String _extractAuthor(String content) {
    if (content.isEmpty) return '未知作者';

    final lines = content.split('\n').take(50).toList();
    for (var line in lines) {
      line = line.trim();
      if (line.contains('作者') || line.contains('著')) {
        return line
            .replaceAll('作者：', '')
            .replaceAll('作者:', '')
            .replaceAll('著', '')
            .trim();
      }
    }
    return '未知作者';
  }

  Future<String> readNovelContent(String filePath) async {
    return await _safeReadFile(filePath);
  }

  Future<bool> exportNovel(Novel novel) async {
    try {
      debugPrint('开始导出小说: ${novel.title}');
      debugPrint('源文件路径: ${novel.filePath}');

      final content = await readNovelContent(novel.filePath);
      debugPrint('读取到内容长度: ${content.length} 字符');

      if (content.isEmpty) {
        debugPrint('警告: 文件内容为空');
      }

      final bytes = utf8.encode(content);
      debugPrint('编码后字节长度: ${bytes.length}');

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出小说',
        fileName: '${novel.title}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: bytes,
      );

      if (outputPath == null) {
        debugPrint('用户取消了导出');
        return false;
      }

      debugPrint('目标文件路径: $outputPath');
      debugPrint('文件写入成功');
      return true;
    } catch (e) {
      debugPrint('导出失败: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      return false;
    }
  }
}

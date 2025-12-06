import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:novel_reader/core/themes/app_theme.dart';
import 'package:novel_reader/presentation/bloc/novel_provider.dart';
import 'package:novel_reader/presentation/screens/library_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NovelProvider(),
      child: MaterialApp(
        title: '小说阅读器',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const LibraryScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'navigation/reader_router.dart';
import 'theme/reader_theme.dart';

/// Root widget of the TITAN Reader application.
class TitanReaderApp extends StatelessWidget {
  const TitanReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TITAN Reader',
      debugShowCheckedModeBanner: false,
      theme: ReaderTheme.lightTheme,
      darkTheme: ReaderTheme.darkTheme,
      routerConfig: readerRouter,
    );
  }
}

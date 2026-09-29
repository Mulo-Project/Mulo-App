import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/design.dart';
import '../features/design_preview/design_preview_screen.dart';

class MusicApp extends ConsumerWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeControllerProvider.select((s) => s.palette));

    return MaterialApp(
      title: 'Music',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(palette),
      themeMode: ThemeMode.dark,
      darkTheme: buildAppTheme(palette),
      // 테마 소스가 바뀌면 AnimatedTheme이 AppThemeTokens.lerp로 넘긴다.
      themeAnimationDuration: AppMotion.themeSwap,
      themeAnimationCurve: AppMotion.standard,
      home: const DesignPreviewScreen(),
    );
  }
}

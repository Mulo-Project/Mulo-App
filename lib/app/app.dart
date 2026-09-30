import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../core/l10n/l10n.dart';
import 'router.dart';

class MusicApp extends ConsumerStatefulWidget {
  const MusicApp({super.key, this.initialLocation = Routes.library});

  /// 테스트 · 스크린샷에서 첫 화면을 바꿀 때 쓴다.
  final String initialLocation;

  @override
  ConsumerState<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends ConsumerState<MusicApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(t.light),
      darkTheme: buildAppTheme(t.dark),
      themeMode: t.mode.material,
      // 테마 소스가 바뀌면 AnimatedTheme이 AppThemeTokens.lerp로 넘긴다.
      themeAnimationDuration: AppMotion.themeSwap,
      themeAnimationCurve: AppMotion.standard,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // 지원하지 않는 기기 언어는 한국어로.
      localeResolutionCallback: (locale, supported) => supported.firstWhere(
        (l) => l.languageCode == locale?.languageCode,
        orElse: () => const Locale('ko'),
      ),
      routerConfig: _router,
      // 상태 표시줄 아이콘을 배경 밝기에 맞춘다.
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: child!,
        );
      },
    );
  }
}

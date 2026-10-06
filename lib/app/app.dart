import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../core/di/injector.dart';
import '../core/l10n/l10n.dart';
import '../features/covers/presentation/bloc/cover_color_cubit.dart';
import '../features/covers/presentation/bloc/cover_cubit.dart';
import '../features/lyrics/presentation/bloc/lyrics_cubit.dart';
import '../features/downloads/presentation/bloc/download_queue_cubit.dart';
import '../features/downloads/presentation/bloc/download_settings_cubit.dart';
import '../features/home/presentation/bloc/play_recorder_cubit.dart';
import '../features/library/presentation/bloc/library_cubit.dart';
import '../features/library/presentation/bloc/library_import_cubit.dart';
import '../features/player/presentation/bloc/audio_output_cubit.dart';
import '../features/player/presentation/bloc/now_playing_cubit.dart';
import '../features/player/presentation/bloc/player_style_cubit.dart';
import '../features/playlists/presentation/bloc/playlists_cubit.dart';
import '../features/search/presentation/bloc/preview_cubit.dart';
import '../features/security/presentation/bloc/app_lock_cubit.dart';
import '../features/security/presentation/widgets/lock_gate.dart';
import '../features/theme/presentation/bloc/theme_cubit.dart';
import 'router.dart';

/// 앱 루트. 앱 전체에서 쓰는 bloc은 MaterialApp 위에 두어
/// 탭 화면 · 전체 화면 플레이어 · 바텀시트 어디서든 읽을 수 있게 한다.
class MusicApp extends StatefulWidget {
  const MusicApp({super.key, this.initialLocation = Routes.home});

  /// 테스트 · 스크린샷에서 첫 화면을 바꿀 때 쓴다.
  final String initialLocation;

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeCubit>()..load()),
        BlocProvider(create: (_) => sl<AppLockCubit>()..load()),
        BlocProvider(create: (_) => sl<CoverCubit>()..load()),
        BlocProvider(create: (_) => sl<CoverColorCubit>()..load()),
        BlocProvider(create: (_) => sl<LyricsCubit>()),
        BlocProvider(create: (_) => sl<LibraryCubit>()..start()),
        BlocProvider(create: (_) => sl<LibraryImportCubit>()),
        BlocProvider(create: (_) => sl<NowPlayingCubit>()),
        BlocProvider(create: (_) => sl<AudioOutputCubit>()..refresh()),
        BlocProvider(create: (_) => sl<PlayerStyleCubit>()..load()),
        BlocProvider(create: (_) => sl<PlayRecorderCubit>()),
        BlocProvider(create: (_) => sl<PreviewCubit>()),
        BlocProvider(create: (_) => sl<DownloadQueueCubit>()..start()),
        BlocProvider(create: (_) => sl<DownloadSettingsCubit>()..load()),
        // 곡 메뉴에서 바로 읽으므로 재생목록 탭을 열기 전에도 미리 불러 둔다.
        BlocProvider(lazy: false, create: (_) => sl<PlaylistsCubit>()..start()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, t) => MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(t.light),
          darkTheme: buildAppTheme(t.dark),
          themeMode: t.materialMode,
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
              value: dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: LockGate(child: child!),
            );
          },
        ),
      ),
    );
  }
}

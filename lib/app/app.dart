import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../core/di/injector.dart';
import '../core/l10n/l10n.dart';
import '../features/account/presentation/bloc/account_cubit.dart';
import '../features/covers/presentation/bloc/cover_color_cubit.dart';
import '../features/covers/presentation/bloc/cover_cubit.dart';
import '../features/lyrics/presentation/bloc/lyrics_cubit.dart';
import '../features/lyrics/presentation/bloc/lyrics_overlay_cubit.dart';
import '../features/lyrics/presentation/bloc/lyrics_settings_cubit.dart';
import '../features/lyrics/presentation/widgets/lyrics_overlay_bridge.dart';
import '../features/downloads/presentation/bloc/download_queue_cubit.dart';
import '../features/downloads/presentation/widgets/download_completion_listener.dart';
import '../features/downloads/presentation/bloc/download_preferences_cubit.dart';
import '../features/downloads/presentation/bloc/download_settings_cubit.dart';
import '../features/equalizer/presentation/bloc/equalizer_cubit.dart';
import '../features/equalizer/presentation/bloc/equalizer_library_cubit.dart';
import '../features/home/presentation/bloc/play_recorder_cubit.dart';
import '../features/library/presentation/bloc/library_cubit.dart';
import '../features/library/presentation/bloc/library_import_cubit.dart';
import '../features/notifications/presentation/bloc/notification_settings_cubit.dart';
import '../features/notifications/presentation/bloc/notification_sync_cubit.dart';
import '../features/notifications/presentation/widgets/notification_bridge.dart';
import '../features/player/presentation/bloc/audio_output_cubit.dart';
import '../features/player/presentation/bloc/video_surface_cubit.dart';
import '../features/player/presentation/bloc/now_playing_cubit.dart';
import '../features/player/presentation/bloc/output_behavior_cubit.dart';
import '../features/player/presentation/bloc/mix_with_others_cubit.dart';
import '../features/player/presentation/bloc/playback_speed_cubit.dart';
import '../features/player/presentation/bloc/player_style_cubit.dart';
import '../features/playlists/presentation/bloc/playlists_cubit.dart';
import '../features/search/presentation/bloc/preview_cubit.dart';
import '../features/search/presentation/bloc/video_quality_cubit.dart';
import '../features/search/domain/entities/media_info.dart';
import '../features/search/presentation/screens/media_detail_screen.dart';
import '../features/security/presentation/bloc/app_lock_cubit.dart';
import '../features/security/presentation/widgets/lock_gate.dart';
import '../features/subscriptions/presentation/widgets/new_videos_launcher.dart';
import '../features/subscriptions/presentation/widgets/new_videos_sheet.dart';
import '../features/theme/presentation/bloc/theme_cubit.dart';
import '../features/theme/presentation/widgets/mood_theme_follower.dart';
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

  /// 재생 알림을 눌렀을 때: 미리 듣기 알림이면 그 영상의 상세 화면을, 아니면 현재 곡의 플레이어 화면을 연다
  /// (플레이어가 이미 열려 있으면 그대로).
  Future<void> _openPlayer() async {
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    final preview = context.read<PreviewCubit>();
    final nowPlaying = context.read<NowPlayingCubit>();
    // 앱이 막 켜졌다면 알림에 떠 있던 미리 듣기를 아직 못 읽었을 수 있어 먼저 맞춘다.
    await preview.syncWithPlayer();
    final hit = preview.state.hit;
    if (hit != null && preview.state.status != PreviewStatus.idle) {
      _openDownload(hit);
      return;
    }
    if (nowPlaying.state.track == null) return;
    if (_router.routerDelegate.currentConfiguration.uri.path != Routes.player) {
      _router.push(Routes.player);
    }
  }

  /// 받기 알림을 눌렀을 때: 그 곡의 상세 화면을 맨 위에 연다.
  void _openDownload(MediaHit hit) {
    _router.routerDelegate.navigatorKey.currentState?.push<void>(
      MaterialPageRoute(builder: (_) => MediaDetailScreen(hit: hit)),
    );
  }

  /// 새 영상 안내 · 알림을 눌렀을 때: 구독 채널의 새 영상 목록을 바텀시트로 연다 (이미 열려 있으면 그대로).
  void _openNewVideos() {
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context != null) showNewVideosSheet(context);
  }

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
        BlocProvider(create: (_) => sl<AccountCubit>()..load()),
        BlocProvider(create: (_) => sl<CoverCubit>()..load()),
        BlocProvider(create: (_) => sl<CoverColorCubit>()..load()),
        BlocProvider(create: (_) => sl<LyricsCubit>()),
        BlocProvider(create: (_) => sl<LyricsSettingsCubit>()..load()),
        BlocProvider(create: (_) => sl<LyricsOverlayCubit>()),
        BlocProvider(create: (_) => sl<LibraryCubit>()..start()),
        BlocProvider(
          create: (_) => sl<LibraryImportCubit>()..embedTagsInBackground(),
        ),
        BlocProvider(create: (_) => sl<NowPlayingCubit>()),
        BlocProvider(
          create: (_) => sl<AudioOutputCubit>()
            ..refresh()
            ..watch(),
        ),
        BlocProvider(create: (_) => sl<PlayerStyleCubit>()..load()),
        BlocProvider(create: (_) => sl<MixWithOthersCubit>()..load()),
        BlocProvider(create: (_) => sl<VideoQualityCubit>()..load()),
        BlocProvider(create: (_) => sl<OutputBehaviorCubit>()..load()),
        // 시작할 때 저장된 재생 속도를 재생 엔진에 반영해야 하므로 바로 만든다.
        BlocProvider(
          lazy: false,
          create: (_) => sl<PlaybackSpeedCubit>()..load(),
        ),
        // 시작할 때 저장된 이퀄라이저 값을 재생 엔진에 반영해야 하므로 바로 만든다.
        BlocProvider(lazy: false, create: (_) => sl<EqualizerCubit>()..load()),
        BlocProvider(create: (_) => sl<EqualizerLibraryCubit>()..load()),
        BlocProvider(create: (_) => sl<PlayRecorderCubit>()),
        BlocProvider(create: (_) => sl<PreviewCubit>()),
        BlocProvider(create: (_) => sl<VideoSurfaceCubit>()),
        BlocProvider(create: (_) => sl<DownloadQueueCubit>()..start()),
        BlocProvider(create: (_) => sl<DownloadSettingsCubit>()..load()),
        BlocProvider(create: (_) => sl<DownloadPreferencesCubit>()..load()),
        BlocProvider(
          lazy: false,
          create: (_) => sl<NotificationSettingsCubit>()..load(),
        ),
        BlocProvider(lazy: false, create: (_) => sl<NotificationSyncCubit>()),
        // 곡 메뉴에서 바로 읽으므로 재생목록 탭을 열기 전에도 미리 불러 둔다.
        BlocProvider(lazy: false, create: (_) => sl<PlaylistsCubit>()..start()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        // 화면에 보이는 색 · 모드가 바뀔 때만 앱 전체를 다시 만든다
        // (프리셋 선택 기록 · 미리보기 표시만 바뀌는 상태는 거른다).
        buildWhen: (a, b) =>
            a.dark != b.dark || a.light != b.light || a.mode != b.mode,
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
              child: NotificationBridge(
                onOpenPlayer: _openPlayer,
                onOpenDownload: _openDownload,
                child: LyricsOverlayBridge(
                  child: MoodThemeFollower(
                    child: DownloadCompletionListener(
                      child: NewVideosLauncher(
                        onOpen: _openNewVideos,
                        child: LockGate(child: child!),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

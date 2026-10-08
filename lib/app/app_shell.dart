import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../core/l10n/l10n.dart';
import '../features/covers/presentation/bloc/cover_cubit.dart';
import '../features/library/domain/entities/track.dart' show formatDuration;
import '../features/home/presentation/bloc/play_recorder_cubit.dart';
import '../features/player/presentation/bloc/audio_output_cubit.dart';
import '../features/player/presentation/bloc/now_playing_cubit.dart';
import '../features/search/presentation/bloc/preview_cubit.dart';
import '../core/cache/cached_web_image.dart';
import '../features/downloads/presentation/bloc/download_queue_cubit.dart';
import '../features/downloads/presentation/widgets/download_bar.dart';
import '../features/downloads/presentation/widgets/download_float_button.dart';
import '../features/search/presentation/screens/media_detail_screen.dart';
import '../features/theme/presentation/bloc/theme_cubit.dart';
import 'router.dart';
import 'theme_preview_bar.dart';

/// 탭 화면 공통 틀: 배경 · 탭 내용 · 가로 전체 유리 미니 플레이어 · 단색 하단 탭.
/// 재생 상태를 따라 재생 기록(곡 · 실제 재생 시간)을 남긴다.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  StatefulNavigationShell get shell => widget.shell;

  /// 받기 줄을 접어 플로팅 버튼으로 둔 상태와 그 버튼의 자리 (앱을 켜 두는 동안만).
  var _downloadMinimized = false;
  Offset? _floatPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    // 내용이 유리 미니 플레이어 · 탭 바 뒤로 흘러가도록 extendBody.
    // 화면은 MediaQuery.paddingOf(context).bottom 만큼 아래 여백을 둔다.
    return BlocListener<DownloadQueueCubit, DownloadQueueState>(
      // 받을 곡이 모두 사라지면 다음 받기는 받기 줄로 다시 시작한다.
      listenWhen: (a, b) => a.current != null && b.current == null,
      listener: (context, _) => setState(() {
        _downloadMinimized = false;
        _floatPosition = null;
      }),
      child: BlocListener<NowPlayingCubit, NowPlayingState>(
        listener: (context, s) =>
            context.read<PlayRecorderCubit>().playbackChanged(
              trackId: s.track?.id,
              position: s.position,
              isPlaying: s.isPlaying,
            ),
        child: BlocListener<NowPlayingCubit, NowPlayingState>(
          // 곡이 바뀌거나 재생을 시작 · 멈출 때 출력 기기를 다시 확인한다.
          listenWhen: (a, b) =>
              a.track?.id != b.track?.id || a.isPlaying != b.isPlaying,
          listener: (context, _) => context.read<AudioOutputCubit>().refresh(),
          child: BlocListener<NowPlayingCubit, NowPlayingState>(
            // 메인 재생이 시작되면 미리 듣기는 멈춘다 (두 소리가 겹치지 않게).
            listenWhen: (a, b) => !a.isPlaying && b.isPlaying,
            listener: (context, _) => context.read<PreviewCubit>().stop(),
            child: BlocListener<PreviewCubit, PreviewState>(
              // 미리 듣기가 재생 중에 막혔으면 까닭을 알린다.
              listenWhen: (a, b) => b.error != null && a.error != b.error,
              listener: (context, s) => ScaffoldMessenger.of(context)
                  .showSnackBar(
                    SnackBar(
                      content: Text('${l10n.searchPreviewFailed}\n${s.error}'),
                    ),
                  ),
              child: Scaffold(
                backgroundColor: p.background,
                extendBody: true,
                body: Stack(
                  children: [
                    AppBackground(child: shell),
                    Positioned.fill(
                      // 버튼은 접힐 때 하단에서 커지며 나타나고, 펴질 때 작아지며 사라진다.
                      child: AnimatedSwitcher(
                        duration: AppMotion.medium,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: AppMotion.emphasized,
                              ),
                              alignment: Alignment.bottomCenter,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, ?current],
                        ),
                        child: _downloadMinimized
                            ? DownloadFloatButton(
                                key: const ValueKey('download-float-on'),
                                position: _floatPosition,
                                onMoved: (o) =>
                                    setState(() => _floatPosition = o),
                                onRestore: () => setState(() {
                                  _downloadMinimized = false;
                                }),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('download-float-off'),
                              ),
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (context.select((ThemeCubit c) => c.state.previewing))
                      const ThemePreviewBar(),
                    // 받는 곡이 있으면 모든 탭에서 보이는 얇은 진행 줄 (눌러서 목록 펼치기).
                    // 접고 펼 때 아래로 접히고 위로 펴지는 움직임을 준다.
                    AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.bottomCenter,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: _downloadMinimized
                          ? const SizedBox.shrink(
                              key: ValueKey('download-gone'),
                            )
                          : DownloadBar(
                              key: const ValueKey('download-shown'),
                              onMinimize: () => setState(() {
                                _downloadMinimized = true;
                                _floatPosition = null;
                              }),
                            ),
                    ),
                    const _ShellMiniPlayer(),
                    AppBottomNav(
                      currentIndex: shell.currentIndex,
                      onSelected: (i) {
                        shell.goBranch(
                          i,
                          initialLocation: i == shell.currentIndex,
                        );
                      },
                      items: [
                        AppNavItem(
                          icon: AppIcons.libraryOutline,
                          selectedIcon: AppIcons.library,
                          label: l10n.navLibrary,
                        ),
                        AppNavItem(
                          icon: AppIcons.queueOutline,
                          selectedIcon: AppIcons.queue,
                          label: l10n.navPlaylists,
                        ),
                        AppNavItem(
                          icon: AppIcons.homeOutline,
                          selectedIcon: AppIcons.home,
                          label: l10n.navHome,
                          highlighted: true,
                        ),
                        AppNavItem(
                          icon: AppIcons.searchOutline,
                          selectedIcon: AppIcons.search,
                          label: l10n.navSearch,
                        ),
                        AppNavItem(
                          icon: AppIcons.tuneOutline,
                          selectedIcon: AppIcons.tune,
                          label: l10n.navSettings,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 미니 플레이어. 미리 듣는 동안은 미리 듣는 곡이 이 자리를 대신한다
/// (누르면 그 곡의 상세 화면). 재생 대기열과 위치는 건드리지 않아서,
/// 미리 듣기가 끝나면 듣던 대기열이 그대로 돌아온다.
class _ShellMiniPlayer extends StatelessWidget {
  const _ShellMiniPlayer();

  @override
  Widget build(BuildContext context) {
    final preview = context.watch<PreviewCubit>().state;
    if (preview.status != PreviewStatus.idle) {
      return _PreviewMiniPlayer(preview: preview);
    }
    final state = context.watch<NowPlayingCubit>().state;
    final track = state.track;
    if (track == null) return const SizedBox.shrink();
    final vm = context.read<NowPlayingCubit>();
    final l10n = context.l10n;

    return Hero(
      tag: 'now-playing',
      child: MiniPlayerBar(
        title: track.title,
        artist: track.artist,
        artwork: coverImageOf(context, CoverKey.track(track.id)),
        progress: state.progress,
        isPlaying: state.isPlaying,
        playLabel: l10n.actionPlay,
        pauseLabel: l10n.actionPause,
        previousLabel: l10n.actionPrevious,
        nextLabel: l10n.actionNext,
        positionText: formatDuration(state.position),
        durationText: formatDuration(track.duration),
        queueLabel: l10n.playerQueue,
        onTap: () => context.push(Routes.player),
        onPlayPause: vm.togglePlay,
        onPrevious: vm.previous,
        onNext: vm.next,
        onQueue: () => context.push(Routes.queue),
      ),
    );
  }
}

class _PreviewMiniPlayer extends StatelessWidget {
  const _PreviewMiniPlayer({required this.preview});

  final PreviewState preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PreviewCubit>();
    final hit = preview.hit;
    final loading = preview.status == PreviewStatus.loading;
    final duration = preview.progress?.duration;
    final thumb = hit?.thumbnailUrl;
    return MiniPlayerBar(
      key: const ValueKey('preview-mini-player'),
      title: preview.title,
      artist: loading
          ? l10n.searchPreviewLoading
          : [
              l10n.searchPreview,
              if (hit?.uploader case final u? when u.isNotEmpty) u,
            ].join(' · '),
      artwork: thumb == null ? null : CachedWebImage(thumb),
      progress: preview.fraction,
      isPlaying: !preview.paused,
      playLabel: l10n.searchPreviewResume,
      pauseLabel: l10n.searchPreviewPause,
      previousLabel: l10n.actionPrevious,
      nextLabel: l10n.actionNext,
      positionText: formatDuration(preview.progress?.position ?? Duration.zero),
      durationText: duration == null ? '--:--' : formatDuration(duration),
      queueLabel: l10n.searchPreviewStop,
      showSkip: false,
      queueIcon: AppIcons.close,
      onTap: hit == null ? null : () => showMediaDetail(context, hit),
      onPlayPause: loading ? null : cubit.togglePause,
      onQueue: cubit.stop,
    );
  }
}

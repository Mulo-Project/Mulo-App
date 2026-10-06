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
import '../features/theme/presentation/bloc/theme_cubit.dart';
import 'router.dart';
import 'theme_preview_bar.dart';

/// 탭 화면 공통 틀: 배경 · 탭 내용 · 가로 전체 유리 미니 플레이어 · 단색 하단 탭.
/// 재생 상태를 따라 재생 기록(곡 · 실제 재생 시간)을 남긴다.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    // 내용이 유리 미니 플레이어 · 탭 바 뒤로 흘러가도록 extendBody.
    // 화면은 MediaQuery.paddingOf(context).bottom 만큼 아래 여백을 둔다.
    return BlocListener<NowPlayingCubit, NowPlayingState>(
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
              body: AppBackground(child: shell),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (context.select((ThemeCubit c) => c.state.previewing))
                    const ThemePreviewBar(),
                  const _ShellMiniPlayer(),
                  AppBottomNav(
                    currentIndex: shell.currentIndex,
                    onSelected: (i) {
                      // 다른 탭으로 가면 미리 듣기는 멈춘다.
                      if (i != shell.currentIndex) {
                        context.read<PreviewCubit>().stop();
                      }
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
    );
  }
}

class _ShellMiniPlayer extends StatelessWidget {
  const _ShellMiniPlayer();

  @override
  Widget build(BuildContext context) {
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

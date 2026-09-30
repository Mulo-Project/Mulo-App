import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../core/l10n/l10n.dart';
import '../features/covers/presentation/bloc/cover_cubit.dart';
import '../features/home/presentation/bloc/play_recorder_cubit.dart';
import '../features/player/presentation/bloc/now_playing_cubit.dart';
import 'router.dart';

/// 탭 화면 공통 틀: 배경 · 탭 내용 · 유리 미니 플레이어 · 단색 하단 탭.
/// 재생 중인 곡이 바뀌면 재생 기록을 남긴다.
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
      listenWhen: (a, b) =>
          b.isPlaying && b.track != null && a.track?.id != b.track?.id,
      listener: (context, s) =>
          context.read<PlayRecorderCubit>().trackStarted(s.track!.id),
      child: Scaffold(
        backgroundColor: p.background,
        extendBody: true,
        body: AppBackground(child: shell),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ShellMiniPlayer(),
            AppBottomNav(
              currentIndex: shell.currentIndex,
              onSelected: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
              items: [
                AppNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: l10n.navHome,
                ),
                AppNavItem(
                  icon: Icons.library_music_outlined,
                  selectedIcon: Icons.library_music_rounded,
                  label: l10n.navLibrary,
                ),
                AppNavItem(
                  icon: Icons.queue_music_outlined,
                  selectedIcon: Icons.queue_music_rounded,
                  label: l10n.navPlaylists,
                ),
                AppNavItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search_rounded,
                  label: l10n.navSearch,
                ),
                AppNavItem(
                  icon: Icons.tune_outlined,
                  selectedIcon: Icons.tune_rounded,
                  label: l10n.navSettings,
                ),
              ],
            ),
          ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Hero(
        tag: 'now-playing',
        child: MiniPlayerBar(
          title: track.title,
          artist: track.artist,
          artwork: coverImageOf(context, CoverKey.track(track.id)),
          progress: state.progress,
          isPlaying: state.isPlaying,
          playLabel: l10n.actionPlay,
          pauseLabel: l10n.actionPause,
          nextLabel: l10n.actionNext,
          onTap: () => context.push(Routes.player),
          onPlayPause: vm.togglePlay,
          onNext: vm.next,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../core/l10n/l10n.dart';
import '../features/covers/presentation/cover_controller.dart';
import '../features/player/presentation/now_playing_view_model.dart';
import 'router.dart';

/// 탭 화면 공통 틀: 빛 배경 · 탭 내용 · 유리 미니 플레이어 · 유리 하단 탭.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;

    // 내용이 유리 미니 플레이어 · 탭 바 뒤로 흘러가도록 extendBody.
    // 화면은 MediaQuery.paddingOf(context).bottom 만큼 아래 여백을 둔다.
    return Scaffold(
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
                icon: Icons.download_outlined,
                selectedIcon: Icons.download_rounded,
                label: l10n.navDownloads,
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
    );
  }
}

class _ShellMiniPlayer extends ConsumerWidget {
  const _ShellMiniPlayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nowPlayingProvider);
    final track = state.track;
    if (track == null) return const SizedBox.shrink();
    final vm = ref.read(nowPlayingProvider.notifier);
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
          artwork: coverImageOf(ref, CoverKey.track(track.id)),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../bloc/playlists_cubit.dart';
import '../widgets/playlist_card.dart';

/// 재생목록 카드 순서 바꾸기: 길게 눌러 끌어서 위아래로 옮기면 바로 저장되고,
/// 재생목록 탭의 카드가 그 순서로 놓인다. 좋아요 목록은 늘 맨 앞이라 움직이지 않는다.
class PlaylistReorderScreen extends StatelessWidget {
  const PlaylistReorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final cubit = context.read<PlaylistsCubit>();
    final all = context.watch<PlaylistsCubit>().state;
    final favorites = all.where((e) => e.isFavorites).firstOrNull;
    final lists = [
      for (final e in all)
        if (!e.isFavorites) e,
    ];

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.playlistReorderTitle,
                leading: const AppBackButton(),
              ),
              Padding(
                padding: AppSpacing.screen.copyWith(bottom: AppSpacing.sm),
                child: Text(
                  l10n.playlistReorderHint,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: p.onSurfaceMuted),
                ),
              ),
              // 좋아요 목록은 늘 맨 앞 (끌 수 없다).
              if (favorites != null) _Row(playlist: favorites, locked: true),
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.only(
                    bottom:
                        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                  ),
                  // 길게 눌러야 끌린다 (기본 손잡이는 쓰지 않는다).
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, _, _) => Material(
                    color: p.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    elevation: 0,
                    child: child,
                  ),
                  itemCount: lists.length,
                  onReorderItem: (from, to) {
                    final ids = [for (final e in lists) e.id];
                    ids.insert(to, ids.removeAt(from));
                    cubit.reorder(ids);
                  },
                  itemBuilder: (context, i) =>
                      ReorderableDelayedDragStartListener(
                        key: ValueKey(lists[i].id),
                        index: i,
                        child: _Row(playlist: lists[i]),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 한 줄: 커버 · 이름 · 곡 수, 오른쪽에 끌기 표시 (좋아요 목록은 자물쇠 대신 하트가 커버라 표시만 흐리게).
class _Row extends StatelessWidget {
  const _Row({required this.playlist, this.locked = false});

  final Playlist playlist;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final key = CoverKey.playlist(playlist.id);
    return TrackTile(
      title: playlistNameOf(l10n, playlist),
      subtitle: l10n.songCount(playlist.trackCount),
      tone: playlistToneOf(playlist),
      color: coverColorOf(context, key),
      artwork: coverImageOf(context, key),
      leading: playlist.isFavorites && coverImageOf(context, key) == null
          ? ArtworkBox(
              tone: playlistToneOf(playlist),
              color: coverColorOf(context, key),
              icon: AppIcons.favorite,
            )
          : null,
      trailing: Icon(
        AppIcons.dragHandle,
        color: locked ? p.outline : p.onSurfaceMuted,
      ),
    );
  }
}

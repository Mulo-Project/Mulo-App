import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/track_list_tile.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/playlist_tracks_cubit.dart';
import '../bloc/playlists_cubit.dart';
import '../widgets/playlist_card.dart';
import '../widgets/playlist_menu.dart';

/// 재생목록 상세: 커버 · 전체 재생 · 담긴 곡.
/// 곡 메뉴의 삭제는 "재생목록에서 빼기"와 "파일 삭제"로 나뉜다.
class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlaylistTracksCubit>()..start(playlistId),
      child: _Body(playlistId: playlistId),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final pl = context.select<PlaylistsCubit, Playlist?>(
      (c) => c.state.where((e) => e.id == playlistId).firstOrNull,
    );
    final tracks = context.watch<PlaylistTracksCubit>().state;
    final image = coverImageOf(context, CoverKey.playlist(playlistId));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            title: pl == null ? '' : playlistNameOf(l10n, pl),
            leading: CircleIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: l10n.actionBack,
              onPressed: () => context.pop(),
            ),
            actions: [
              if (pl != null)
                Builder(
                  builder: (btn) => CircleIconButton(
                    icon: Icons.more_vert_rounded,
                    tooltip: l10n.playlistMenuTooltip,
                    onPressed: () => showPlaylistMenu(
                      btn,
                      pl,
                      onDeleted: () {
                        if (context.mounted) context.pop();
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (pl == null)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.playlistNotFound,
                style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              ),
            )
          else ...[
            Padding(
              padding: AppSpacing.screen,
              child: AspectRatio(
                aspectRatio: 2,
                child: CoverCard(
                  image: image,
                  tone: playlistToneOf(pl),
                  shade: image != null,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          playlistNameOf(l10n, pl),
                          style: text.headlineSmall?.copyWith(color: p.onGlow),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.songCount(pl.trackCount),
                          style: text.bodyMedium?.copyWith(color: p.onGlow),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.screen,
              child: PillButton(
                label: l10n.playlistMenuPlayAll,
                icon: Icons.play_arrow_rounded,
                onPressed: tracks == null || tracks.isEmpty
                    ? null
                    : () => context.read<NowPlayingCubit>().playQueue(tracks),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (tracks != null && tracks.isEmpty)
              Padding(
                padding: AppSpacing.screen.copyWith(top: AppSpacing.md),
                child: Text(
                  l10n.playlistDetailEmpty,
                  style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                ),
              )
            else
              for (final (i, t) in (tracks ?? const <Track>[]).indexed)
                TrackListTile(
                  track: t,
                  queue: tracks!,
                  index: i,
                  playlistId: playlistId,
                ),
          ],
        ],
      ),
    );
  }
}

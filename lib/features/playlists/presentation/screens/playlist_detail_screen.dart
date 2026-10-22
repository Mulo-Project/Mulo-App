import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_item_widgets.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/play_shuffle_row.dart';
import '../../../library/presentation/widgets/lazy_track_list.dart';
import '../../../library/presentation/widgets/track_list_tile.dart';
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
    final downloads = context.select<DownloadQueueCubit, List<DownloadItem>>(
      (c) => c.state.unfinishedFor(playlistId),
    );
    final image = coverImageOf(context, CoverKey.playlist(playlistId));

    return SafeArea(
      bottom: false,
      child: LazyTrackList(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        header: [
          AppTopBar(
            title: pl == null ? '' : playlistNameOf(l10n, pl),
            leading: const AppBackButton(),
            actions: [
              if (pl != null)
                Builder(
                  builder: (btn) => CircleIconButton(
                    icon: AppIcons.more,
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
                  color: coverColorOf(context, CoverKey.playlist(pl.id)),
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
            PlayShuffleRow(
              tracks: tracks ?? const <Track>[],
              playLabel: l10n.playlistMenuPlayAll,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (downloads.isNotEmpty)
              _Downloads(playlistId: playlistId, items: downloads),
            if (tracks != null && tracks.isEmpty && downloads.isEmpty)
              Padding(
                padding: AppSpacing.screen.copyWith(top: AppSpacing.md),
                child: Text(
                  l10n.playlistDetailEmpty,
                  style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                ),
              ),
          ],
        ],
        trackCount: tracks?.length ?? 0,
        trackBuilder: (context, i) => TrackListTile(
          track: tracks![i],
          queue: tracks,
          index: i,
          playlistId: playlistId,
          showNumber: true,
        ),
      ),
    );
  }
}

/// 이 재생목록에 담으려고 받는 곡들: 곡마다 진행도, 맨 위에 전체 취소.
class _Downloads extends StatelessWidget {
  const _Downloads({required this.playlistId, required this.items});

  final String playlistId;
  final List<DownloadItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.playlistDownloadsTitle(items.length),
                  style: text.titleSmall?.copyWith(color: p.onSurfaceMuted),
                ),
              ),
              CancelAllDownloadsButton(playlistId: playlistId),
            ],
          ),
        ),
        for (final item in items)
          TrackTile(
            title: item.title,
            subtitle: downloadSubtitle(item),
            tone: toneFor(item.id),
            artwork: downloadThumbnail(item),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.status != DownloadStatus.failed) ...[
                  ProgressLine(value: item.progress, height: 4),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  downloadStatusText(l10n, item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: item.status == DownloadStatus.failed
                        ? p.onSurfaceMuted
                        : p.accent,
                  ),
                ),
              ],
            ),
            trailing: DownloadItemActions(item: item),
          ),
      ],
    );
  }
}

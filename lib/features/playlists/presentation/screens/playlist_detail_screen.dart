import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_item_widgets.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../library/presentation/widgets/play_shuffle_row.dart';
import '../../../library/presentation/widgets/lazy_track_list.dart';
import '../../../library/presentation/widgets/library_selection.dart';
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

class _Body extends StatefulWidget {
  const _Body({required this.playlistId});

  final String playlistId;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with TrackPicker<_Body> {
  String get playlistId => widget.playlistId;

  @override
  String? get pickerPlaylistId => playlistId;

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

    final header = <Widget>[
      AppTopBar(
        title: pl == null ? '' : playlistNameOf(l10n, pl),
        leading: const AppBackButton(),
        actions: [
          // "곡 추가"는 위 막대에서 커버 아래 버튼 줄로 옮겼다 (제목 자리 확보).
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
            aspectRatio: 2.4, // 헤더를 낮춰 곡 목록이 먼저 보이게
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
        // 대표곡: 카드가 아니라 상세 안에서 보여 준다 (누르면 이 재생목록으로 바로 들어 볼 수 있다).
        if (pl.featured != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _FeaturedRow(playlist: pl, featured: pl.featured!),
        ],
        const SizedBox(height: AppSpacing.md),
        // 곡이 없으면 전체 재생 · 셔플 줄은 의미가 없어 숨긴다.
        if (tracks == null || tracks.isNotEmpty) ...[
          PlayShuffleRow(
            tracks: tracks ?? const <Track>[],
            playLabel: l10n.playlistMenuPlayAll,
            extra: pl.isFavorites
                ? null
                : PillButton(
                    label: l10n.playlistAddTracks,
                    icon: AppIcons.add,
                    variant: PillVariant.tonal,
                    snug: true,
                    onPressed: () =>
                        context.push(Routes.playlistAddTracks(playlistId)),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (downloads.isNotEmpty)
          _Downloads(playlistId: playlistId, items: downloads),
      ],
    ];

    // 담긴 곡이 없으면 머리 아래 남은 자리 가운데에 안내와 "곡 추가" 버튼을 둔다.
    // 화면이 낮아 다 안 들어가면 그대로 스크롤된다 (넘쳐 깨지지 않게).
    if (pl != null && tracks != null && tracks.isEmpty && downloads.isEmpty) {
      return SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverList(delegate: SliverChildListDelegate(header)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                ),
                child: EmptyState(
                  // 좋아요 목록은 하트 아이콘과 다른 문구, 직접 만든 목록은 곡 추가 버튼이 있다.
                  icon: pl.isFavorites
                      ? AppIcons.favorite
                      : AppIcons.playlistPlay,
                  title: pl.isFavorites
                      ? l10n.playlistDetailEmptyFavorites
                      : l10n.playlistDetailEmpty,
                  body: pl.isFavorites
                      ? l10n.playlistDetailEmptyFavoritesBody
                      : l10n.playlistDetailEmptyBody,
                  action: pl.isFavorites
                      ? null
                      : PillButton(
                          label: l10n.playlistAddTracks,
                          icon: AppIcons.add,
                          compact: true,
                          onPressed: () => context.push(
                            Routes.playlistAddTracks(playlistId),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          LazyTrackList(
            padding: EdgeInsets.only(
              bottom:
                  AppSpacing.lg +
                  MediaQuery.paddingOf(context).bottom +
                  selectionBottomGap,
            ),
            header: header,
            trackCount: tracks?.length ?? 0,
            trackBuilder: (context, i) => TrackListTile(
              track: tracks![i],
              queue: tracks,
              index: i,
              playlistId: playlistId,
              showNumber: true,
              selection: selectionFor(tracks[i]),
            ),
          ),
          // 하나라도 고르면 하단에 선택 막대가 올라온다.
          ?selectionBar(tracks ?? const <Track>[], tracks ?? const <Track>[]),
        ],
      ),
    );
  }
}

/// 대표곡 한 줄: 작은 이미지 · 제목 · 가수 · 장르, 오른쪽에 미리 듣기(재생 중이면 일시정지) 버튼.
/// 누르면 이 곡부터 이 재생목록 대기열로 재생한다.
class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({required this.playlist, required this.featured});

  final Playlist playlist;
  final PlaylistTrackPreview featured;

  Future<void> _play(BuildContext context) async {
    final player = context.read<NowPlayingCubit>();
    final tracks = await context.read<PlaylistsCubit>().tracksOf(playlist.id);
    final i = tracks.indexWhere((e) => e.id == featured.id);
    if (i >= 0) player.playQueue(tracks, index: i);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = featured;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.playlistFeaturedTitle),
        TrackTile(
          title: t.title,
          subtitle: [
            if (t.artist.isNotEmpty) t.artist,
            t.genre.isEmpty ? l10n.unknownGenre : t.genre,
          ].join(' · '),
          tone: toneFor(t.id),
          artwork: coverImageOf(context, CoverKey.track(t.id)),
          color: coverColorOf(context, CoverKey.track(t.id)),
          onTap: () => _play(context),
          // 이 곡이 재생 중이면 일시정지 아이콘, 아니면 재생 아이콘.
          trailing: BlocBuilder<NowPlayingCubit, NowPlayingState>(
            buildWhen: (a, b) =>
                (a.track?.id == t.id) != (b.track?.id == t.id) ||
                a.isPlaying != b.isPlaying,
            builder: (context, s) {
              final current = s.track?.id == t.id;
              final playing = current && s.isPlaying;
              return IconButton(
                tooltip: playing
                    ? l10n.actionPause
                    : l10n.playlistFeaturedPreview,
                onPressed: current
                    ? context.read<NowPlayingCubit>().togglePlay
                    : () => _play(context),
                icon: Icon(
                  playing ? AppIcons.pauseCircle : AppIcons.playCircle,
                  color: p.accent,
                ),
              );
            },
          ),
        ),
      ],
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

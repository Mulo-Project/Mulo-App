import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_item_widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/playlists_cubit.dart';
import 'playlist_menu.dart';

/// 화면에 보여 줄 이름. 좋아요 목록은 저장된 이름이 없어서 번역된 이름으로 바꾼다.
String playlistNameOf(AppLocalizations l10n, Playlist pl) =>
    pl.isFavorites ? l10n.playlistFavorites : pl.name;

/// 색을 안 골랐을 때 카드의 자동 톤: 좋아요는 보조 색, 나머지는 재생목록마다 다르게.
GlowTone playlistToneOf(Playlist pl) =>
    pl.isFavorites ? GlowTone.secondary : toneFor(pl.id);

/// 재생목록 카드: 얇은 테두리 안에 커버(이미지나 색) · 이름 · 곡 수 · 구분선 · 대표곡 타일 (접으면 제목만 작게, 펼치면 가수 · 이미지가 붙는다).
///
/// 기본(둘러보기)에서는 누르면 재생목록 상세로 가고, ⋮ · 길게 누르기 · 오른쪽 클릭은 팝업 메뉴를 연다.
/// [selected]를 주면 담기 선택 모드: 메뉴 대신 체크 표시가 붙고 [onTap]으로 고른다.
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    this.selected,
    this.already = false,
    this.onTap,
  });

  final Playlist playlist;

  /// null이면 둘러보기, 아니면 담기 선택 모드에서 고른 상태.
  final bool? selected;

  /// 선택 모드에서 이미 곡이 담겨 있는 재생목록.
  final bool already;

  /// 기본은 상세로 이동.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final l10n = context.l10n;
    final image = coverImageOf(context, CoverKey.playlist(playlist.id));
    final color = coverColorOf(context, CoverKey.playlist(playlist.id));
    final browsing = selected == null;

    return _PointerMenu(
      enabled: browsing,
      onMenu: (pos) => showPlaylistMenu(context, playlist, globalPosition: pos),
      child: Material(
        color: p.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(
            color: selected == true ? p.accent : p.outline,
            width: selected == true ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap:
              onTap ?? () => context.push(Routes.playlistDetail(playlist.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 윗면: 재생목록 커버 (이미지나 색). 좋아요는 하트, 선택 모드는 체크.
              AspectRatio(
                aspectRatio: 1.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverCard(
                      radius: 0,
                      image: image,
                      tone: playlistToneOf(playlist),
                      color: color,
                      child: playlist.isFavorites && image == null
                          ? Center(
                              child: Icon(
                                AppIcons.favorite,
                                size: 40,
                                color: p.onGlow.withValues(alpha: .9),
                              ),
                            )
                          : null,
                    ),
                    if (!browsing)
                      Positioned(
                        top: AppSpacing.xxs,
                        right: AppSpacing.xxs,
                        child: _SelectMark(selected: selected!),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.xxs,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        playlistNameOf(l10n, playlist),
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (browsing)
                      Builder(
                        builder: (btn) => SizedBox.square(
                          dimension: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            tooltip: l10n.playlistMenuTooltip,
                            onPressed: () => showPlaylistMenu(btn, playlist),
                            icon: Icon(AppIcons.more, color: p.onSurfaceMuted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  already
                      ? l10n.playlistPickAlready
                      : l10n.songCount(playlist.trackCount),
                  style: text.bodySmall,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const AppDivider(),
              // 대표곡: 남는 높이를 차지하는 칸. 커버 · 제목 · 가수를 또렷하게.
              _Featured(playlist: playlist, expandable: browsing),
            ],
          ),
        ),
      ),
    );
  }
}

/// 길게 누르기 · 오른쪽 클릭의 화면 좌표를 메뉴에 넘긴다.
class _PointerMenu extends StatefulWidget {
  const _PointerMenu({
    required this.enabled,
    required this.onMenu,
    required this.child,
  });

  final bool enabled;
  final ValueChanged<Offset> onMenu;
  final Widget child;

  @override
  State<_PointerMenu> createState() => _PointerMenuState();
}

class _PointerMenuState extends State<_PointerMenu> {
  Offset _last = Offset.zero;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (e) => _last = e.position,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => widget.onMenu(_last),
        onSecondaryTap: () => widget.onMenu(_last),
        child: widget.child,
      ),
    );
  }
}

class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Icon(
        selected ? AppIcons.checkCircle : AppIcons.radioOff,
        size: 26,
        color: selected ? p.accent : p.onGlow,
      ),
    );
  }
}

/// 앱을 켜 둔 동안 펼쳐 둔 카드 (재생목록 id). 화면을 오가도 펼친 채로 둔다.
final _expandedIds = <String>{};

/// 카드 아래 대표곡 타일. 접으면 제목만 작게, 누르면 영역이 커지며 가수와
/// 작은 커버 이미지 · 장르 · 재생 버튼이 나온다. 재생 버튼을 누르면
/// 그 곡을 (이 재생목록 대기열로) 바로 재생해 미리 들어 볼 수 있다.
class _Featured extends StatefulWidget {
  const _Featured({required this.playlist, required this.expandable});

  final Playlist playlist;

  /// 담기 선택 모드에서는 펼치지 않는다.
  final bool expandable;

  @override
  State<_Featured> createState() => _FeaturedState();
}

class _FeaturedState extends State<_Featured> {
  late bool _expanded =
      widget.expandable && _expandedIds.contains(widget.playlist.id);

  void _toggle() => setState(() {
    _expanded = !_expanded;
    _expanded
        ? _expandedIds.add(widget.playlist.id)
        : _expandedIds.remove(widget.playlist.id);
  });

  Future<void> _preview(PlaylistTrackPreview t) async {
    final player = context.read<NowPlayingCubit>();
    final tracks = await context.read<PlaylistsCubit>().tracksOf(
      widget.playlist.id,
    );
    final i = tracks.indexWhere((e) => e.id == t.id);
    if (i >= 0) player.playQueue(tracks, index: i);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final l10n = context.l10n;
    final t = widget.playlist.featured;
    // 접은 줄은 작고 낮게, 카드마다 같은 높이로 맞춘다.
    const rowHeight = 30.0;
    // 이 재생목록에 담을 곡을 받는 중이면 대표곡 자리에 그 곡과 진행 막대를 보인다.
    final dl = context.select<DownloadQueueCubit, DownloadItem?>(
      (c) => c.state.activeFor(widget.playlist.id),
    );
    if (dl != null) return _DownloadingRow(item: dl, minHeight: rowHeight);
    if (t == null) return const SizedBox(height: rowHeight);
    final open = _expanded && widget.expandable;

    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 접으면 제목만 작게, 펼치면 제목이 커지고 아래에 가수가 붙는다.
          InkWell(
            onTap: widget.expandable ? _toggle : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: rowHeight),
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.xxs,
                  top: open ? AppSpacing.xs : 0,
                  bottom: open ? AppSpacing.xxs : 0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 대표곡 제목 · 가수가 칸보다 길면 옆으로 흘러간다.
                          MarqueeText(
                            t.title,
                            style: (open ? text.labelLarge : text.labelSmall)
                                ?.copyWith(color: p.onSurface),
                          ),
                          if (open && t.artist.isNotEmpty)
                            MarqueeText(
                              t.artist,
                              style: text.labelSmall?.copyWith(
                                color: p.onSurfaceMuted,
                              ),
                            ),
                          if (open)
                            Text(
                              t.genre.isEmpty ? l10n.unknownGenre : t.genre,
                              style: text.labelSmall?.copyWith(
                                color: p.onSurfaceMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // 위 줄의 ⋮ 와 같은 칸(28)에 둬서 세로로 줄이 맞는다.
                    if (widget.expandable)
                      SizedBox.square(
                        dimension: 28,
                        child: Icon(
                          open ? AppIcons.expandLess : AppIcons.expandMore,
                          size: AppSizes.iconSm,
                          color: p.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 펼치면 아래에 한 줄이 더 생긴다: 작은 이미지 · 장르 · 재생 버튼.
          if (open)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.xxs,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  ArtworkBox(
                    image: coverImageOf(context, CoverKey.track(t.id)),
                    size: 36,
                    radius: 6,
                    tone: toneFor(t.id),
                    color: coverColorOf(context, CoverKey.track(t.id)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Spacer(),
                  // 이 곡이 재생 중이면 일시정지 아이콘, 아니면 재생 아이콘.
                  BlocBuilder<NowPlayingCubit, NowPlayingState>(
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
                            : () => _preview(t),
                        icon: Icon(
                          playing ? AppIcons.pauseCircle : AppIcons.playCircle,
                          color: p.accent,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 대표곡 자리에 보이는 받기 줄: 받는 곡 제목 · 진행 막대 · 상태(%).
class _DownloadingRow extends StatelessWidget {
  const _DownloadingRow({required this.item, required this.minHeight});

  final DownloadItem item;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: text.labelSmall?.copyWith(color: p.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            ProgressLine(value: item.progress, height: 4),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              downloadStatusText(context.l10n, item),
              style: text.labelSmall?.copyWith(color: p.accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

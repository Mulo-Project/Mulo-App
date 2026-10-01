import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/playlists_cubit.dart';
import 'playlist_menu.dart';

/// 화면에 보여 줄 이름. 좋아요 목록은 저장된 이름이 없어서 번역된 이름으로 바꾼다.
String playlistNameOf(AppLocalizations l10n, Playlist pl) =>
    pl.isFavorites ? l10n.playlistFavorites : pl.name;

/// 이미지가 없는 카드의 색. 안 골랐으면 재생목록마다 다르게 자동으로 정한다.
GlowTone playlistToneOf(Playlist pl) {
  if (pl.isFavorites) return GlowTone.secondary;
  final i = pl.colorIndex;
  if (i == null || i < 0 || i >= GlowTone.values.length) return toneFor(pl.id);
  return GlowTone.values[i];
}

/// 카드 색 이름 (메뉴 · 만들기 화면의 견본 라벨).
String playlistToneName(AppLocalizations l10n, GlowTone tone) => switch (tone) {
  GlowTone.primary => l10n.playlistColorPrimary,
  GlowTone.secondary => l10n.playlistColorSecondary,
  GlowTone.tertiary => l10n.playlistColorTertiary,
};

/// 재생목록 카드: 얇은 테두리 안에 커버(이미지나 색) · 이름 · 곡 수 · 구분선 · 대표곡 타일 (접으면 한 줄, 펼치면 이미지가 앞에 붙는다).
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
                      child: playlist.isFavorites && image == null
                          ? Center(
                              child: Icon(
                                Icons.favorite_rounded,
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
                        style: text.titleSmall,
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
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: p.onSurfaceMuted,
                            ),
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
              Divider(height: 1, thickness: 1, color: p.outline),
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
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        size: 26,
        color: selected ? p.accent : p.onGlow,
      ),
    );
  }
}

/// 앱을 켜 둔 동안 펼쳐 둔 카드 (재생목록 id). 화면을 오가도 펼친 채로 둔다.
final _expandedIds = <String>{};

/// 카드 아래 대표곡 타일. 접으면 이름 · 가수 한 줄, 누르면 아래에 한 줄이 더 생겨
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
    // 접은 줄 높이를 항상 확보해서 카드 높이가 들쭉날쭉하지 않게 한다.
    const rowHeight = 56.0;
    if (t == null) return const SizedBox(height: rowHeight);
    final open = _expanded && widget.expandable;

    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 위 줄은 항상 그대로: 제목 · 가수.
          InkWell(
            onTap: widget.expandable ? _toggle : null,
            child: SizedBox(
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: text.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (t.artist.isNotEmpty)
                            Text(
                              t.artist,
                              style: text.bodySmall?.copyWith(
                                color: p.onSurfaceMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (widget.expandable)
                      Icon(
                        open
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: p.onSurfaceMuted,
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
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      t.genre.isEmpty ? l10n.unknownGenre : t.genre,
                      style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.playlistFeaturedPreview,
                    onPressed: () => _preview(t),
                    icon: Icon(Icons.play_circle_fill_rounded, color: p.accent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

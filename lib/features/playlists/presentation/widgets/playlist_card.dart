import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../domain/entities/playlist.dart';
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

/// 재생목록 카드: 얇은 테두리 안에 커버(이미지나 색) · 이름 · 곡 수 · 구분선 · 대표곡 칸.
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

  /// 카드 칸의 가로 : 세로 (대표곡 칸이 남는 높이를 차지한다).
  static const aspectRatio = .62;

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
    final featured = playlist.featured;

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
              Expanded(child: _Featured(track: featured)),
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

/// 카드 아래 대표곡 칸: 커버 이미지 · 제목 · 가수. 곡이 없으면 칸만 비워 둔다.
class _Featured extends StatelessWidget {
  const _Featured({required this.track});

  final PlaylistTrackPreview? track;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final t = track;
    if (t == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ArtworkBox(
              image: coverImageOf(context, CoverKey.track(t.id)),
              // 칸이 남는 만큼 커진다.
              size: (c.maxHeight - AppSpacing.sm * 2).clamp(40.0, 72.0),
              radius: 8,
              tone: toneFor(t.id),
            ),
            const SizedBox(width: AppSpacing.xs),
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
                      style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

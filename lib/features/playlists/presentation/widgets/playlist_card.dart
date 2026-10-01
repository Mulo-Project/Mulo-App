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

/// 재생목록 카드: 정사각 커버(사용자가 고른 이미지나 색) 아래에 이름 · 곡 수 · 대표곡 한 줄.
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
    final featured = playlist.featured;
    final sub = already
        ? l10n.playlistPickAlready
        : (featured == null
              ? ''
              : (featured.artist.isEmpty
                    ? featured.title
                    : '${featured.title} · ${featured.artist}'));

    return _PointerMenu(
      enabled: browsing,
      onMenu: (pos) => showPlaylistMenu(context, playlist, globalPosition: pos),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => context.push(Routes.playlistDetail(playlist.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 커버: 글자 없이 이미지나 색만. 좋아요는 하트, 선택 모드는 체크.
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverCard(
                    radius: AppRadii.sm,
                    image: image,
                    tone: playlistToneOf(playlist),
                    child: playlist.isFavorites && image == null
                        ? Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 44,
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
            const SizedBox(height: AppSpacing.xs),
            Row(
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
            Text(
              l10n.songCount(playlist.trackCount),
              style: text.bodySmall,
              maxLines: 1,
            ),
            // 대표곡: 한 줄 (없으면 줄만 비워 둬서 카드 높이를 맞춘다).
            Text(
              sub.isEmpty ? ' ' : sub,
              style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

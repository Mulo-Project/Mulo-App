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

/// 재생목록 카드. 유리가 아니라 사용자가 고른 이미지나 색으로 채운다.
/// 아래쪽에 대표곡 하나가 크게 붙는다.
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

  static const aspectRatio = .6;

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
      child: CoverCard(
        image: image,
        tone: playlistToneOf(playlist),
        shade: image != null,
        onTap: onTap ?? () => context.push(Routes.playlistDetail(playlist.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (playlist.isFavorites) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 20,
                        color: p.onGlow,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Expanded(
                    child: Text(
                      playlistNameOf(l10n, playlist),
                      // 사진 · 그라데이션 위라서 두 모드 모두 밝은 글자.
                      style: text.titleMedium?.copyWith(color: p.onGlow),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (browsing)
                    Builder(
                      builder: (btn) => CircleIconButton(
                        icon: Icons.more_vert_rounded,
                        tooltip: l10n.playlistMenuTooltip,
                        size: 34,
                        onPressed: () => showPlaylistMenu(btn, playlist),
                      ),
                    )
                  else
                    _SelectMark(selected: selected!),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  StatNumber(
                    '${playlist.trackCount}',
                    size: 28,
                    color: p.onGlow,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    l10n.unitSongs,
                    style: text.bodySmall?.copyWith(color: p.onGlow),
                  ),
                ],
              ),
              if (already) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.playlistPickAlready,
                  style: text.labelSmall?.copyWith(color: p.onGlow),
                ),
              ],
              const Spacer(),
              _Featured(playlist: playlist),
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

/// 카드 아래 대표곡: 커버 · 제목 · 아티스트를 크게. 곡이 없으면 안내 문구.
class _Featured extends StatelessWidget {
  const _Featured({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final track = playlist.featured;

    if (track == null) {
      // 곡은 있는데 대표곡을 못 구하면(보관함에서 지워진 곡뿐) 자리를 비워 둔다.
      if (playlist.trackCount > 0) return const SizedBox.shrink();
      return Text(
        context.l10n.playlistSummaryEmpty,
        style: text.bodySmall?.copyWith(color: p.onGlow.withValues(alpha: .8)),
      );
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: p.scrim.withValues(alpha: .32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ArtworkBox(
              image: coverImageOf(context, CoverKey.track(track.id)),
              size: 72,
              width: double.infinity,
              radius: AppRadii.sm,
              tone: toneFor(track.id),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              track.title,
              style: text.titleSmall?.copyWith(color: p.onGlow),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (track.artist.isNotEmpty)
              Text(
                track.artist,
                style: text.labelSmall?.copyWith(
                  color: p.onGlow.withValues(alpha: .85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

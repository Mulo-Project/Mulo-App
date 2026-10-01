import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../domain/entities/playlist.dart';
import 'playlist_menu_sheet.dart';

/// 이미지가 없는 카드의 색. 안 골랐으면 재생목록마다 다르게 자동으로 정한다.
GlowTone playlistToneOf(Playlist pl) {
  final i = pl.colorIndex;
  if (i == null || i < 0 || i >= GlowTone.values.length) return toneFor(pl.id);
  return GlowTone.values[i];
}

/// 재생목록 카드. 유리가 아니라 사용자가 고른 이미지나 색으로 채운다.
/// 아래쪽에 많이 들은 곡(없으면 주요 아티스트) 요약이 붙는다.
/// 길게 누르면(이미지 바꾸기 버튼 위에서도) 설정 메뉴가 열린다.
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({super.key, required this.playlist});

  static const aspectRatio = .68;

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final l10n = context.l10n;
    final image = coverImageOf(context, CoverKey.playlist(playlist.id));

    return CoverCard(
      image: image,
      tone: playlistToneOf(playlist),
      shade: image != null,
      onTap: () {},
      onLongPress: () => showPlaylistMenuSheet(context, playlist.id),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    playlist.name,
                    // 사진 · 그라데이션 위라서 두 모드 모두 밝은 글자.
                    style: text.titleMedium?.copyWith(color: p.onGlow),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CircleIconButton(
                  icon: Icons.image_rounded,
                  tooltip: l10n.coverChange,
                  size: 34,
                  onPressed: () => showPlaylistCoverSheet(context, playlist),
                  onLongPress: () =>
                      showPlaylistMenuSheet(context, playlist.id),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                StatNumber('${playlist.trackCount}', size: 28, color: p.onGlow),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  l10n.unitSongs,
                  style: text.bodySmall?.copyWith(color: p.onGlow),
                ),
              ],
            ),
            const Spacer(),
            _Summary(playlist: playlist),
          ],
        ),
      ),
    );
  }
}

/// 카드 아래 요약: 많이 들은 곡 타일, 없으면 주요 아티스트.
class _Summary extends StatelessWidget {
  const _Summary({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    if (playlist.topTracks.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in playlist.topTracks)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: _MiniTile(
                leading: ArtworkBox(
                  image: coverImageOf(context, CoverKey.track(t.id)),
                  size: 24,
                  radius: 6,
                  tone: toneFor(t.id),
                ),
                label: t.title,
              ),
            ),
        ],
      );
    }
    if (playlist.topArtists.isNotEmpty) {
      return Wrap(
        spacing: AppSpacing.xxs,
        runSpacing: AppSpacing.xxs,
        children: [
          for (final a in playlist.topArtists)
            _MiniTile(label: a, maxWidth: 120),
        ],
      );
    }
    // 곡은 있는데 들은 기록 · 아티스트 정보가 없으면 요약 자리를 비워 둔다.
    if (playlist.trackCount > 0) return const SizedBox.shrink();
    return Text(
      context.l10n.playlistSummaryEmpty,
      style: text.bodySmall?.copyWith(color: p.onGlow.withValues(alpha: .8)),
    );
  }
}

/// 요약에 쓰는 작은 타일 (사진 · 그라데이션 위에 얹는 반투명 알약).
class _MiniTile extends StatelessWidget {
  const _MiniTile({this.leading, required this.label, this.maxWidth});

  final Widget? leading;
  final String label;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: p.onGlow);
    final tile = DecoratedBox(
      decoration: ShapeDecoration(
        color: p.scrim.withValues(alpha: .28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          leading == null ? AppSpacing.xs : AppSpacing.xxs,
          AppSpacing.xxs,
          AppSpacing.xs,
          AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
    return maxWidth == null
        ? tile
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: tile,
          );
  }
}

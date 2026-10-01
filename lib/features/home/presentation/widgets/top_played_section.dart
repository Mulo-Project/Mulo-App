import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import 'home_parts.dart';

enum _Kind { tracks, artists, genres }

/// 시상대에 오르는 한 칸 (곡 · 아티스트 · 장르 중 하나).
class _Entry {
  const _Entry(this.title, this.count, this.cover, this.songs);

  final String title;
  final int count;

  /// 이미지를 빌려 올 대표 곡.
  final Track cover;

  /// 이 칸에 속한 곡 (많이 들은 순).
  final List<Track> songs;
}

/// ③ 많이 들은 곡: 곡 · 아티스트 · 장르 칩으로 영역을 고르면 1 · 2 · 3등이 시상대로 서고,
/// 그 아래에 곡 10개 미리보기가 나온다 (접을 수 있다). 아티스트 · 장르는 시상대에서 고른
/// 칸의 곡이 보인다. 제목의 "›"는 많이 들은 곡 TOP 100 상세로 간다.
class TopPlayedSection extends StatefulWidget {
  const TopPlayedSection({
    super.key,
    required this.summary,
    required this.player,
    required this.onMore,
  });

  final HomeSummary summary;
  final NowPlayingCubit player;
  final VoidCallback onMore;

  @override
  State<TopPlayedSection> createState() => _TopPlayedSectionState();
}

class _TopPlayedSectionState extends State<TopPlayedSection> {
  _Kind _kind = _Kind.tracks;

  /// 시상대에서 고른 칸 (곡 영역에서는 쓰지 않는다).
  int _picked = 0;

  List<_Entry> _entries(AppLocalizations l10n) {
    final s = widget.summary;
    return switch (_kind) {
      _Kind.tracks => [
        for (final t in s.topTracks.take(3))
          _Entry(t.track.title, t.count, t.track, [t.track]),
      ],
      _Kind.artists => [
        for (final a in s.stats.topArtists.take(3))
          _Entry(
            a.artist.isEmpty ? l10n.unknownArtist : a.artist,
            a.count,
            a.tracks.first,
            a.tracks,
          ),
      ],
      _Kind.genres => [
        for (final g in s.stats.topGenres.take(3))
          _Entry(g.genre, g.count, g.tracks.first, g.tracks),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final s = widget.summary;
    final player = widget.player;
    final entries = _entries(l10n);
    final picked = _picked.clamp(0, entries.isEmpty ? 0 : entries.length - 1);

    String label(_Kind k) => switch (k) {
      _Kind.tracks => l10n.homeChipTracks,
      _Kind.artists => l10n.homeChipArtists,
      _Kind.genres => l10n.homeChipGenres,
    };

    // 아래 목록: 곡 영역은 TOP 10, 그 밖에는 고른 칸의 곡 10개.
    final List<Track> listed;
    final Map<String, int> counts = {
      for (final t in s.topTracks) t.track.id: t.count,
    };
    String listLabel;
    if (_kind == _Kind.tracks) {
      listed = [for (final t in s.topTracks.take(10)) t.track];
      listLabel = l10n.homeTopTracks;
    } else if (entries.isEmpty) {
      listed = const [];
      listLabel = '';
    } else {
      listed = entries[picked].songs.take(10).toList();
      listLabel = entries[picked].title;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(l10n.homeTopTracks),
        HomeChipRow(
          chips: [
            for (final k in _Kind.values)
              HomeChip(
                label: label(k),
                selected: _kind == k,
                onTap: () => setState(() {
                  _kind = k;
                  _picked = 0;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          Padding(
            padding: AppSpacing.screen,
            child: Text(l10n.homeNoPlays, style: text.bodySmall),
          )
        else ...[
          Padding(
            padding: AppSpacing.screen,
            child: _Podium(
              entries: entries,
              selected: picked,
              onTap: (i) {
                // 곡 영역: 이미 포커스된 칸을 다시 누르면 그 곡을 재생한다.
                if (_kind == _Kind.tracks && i == picked) {
                  player.playQueue([
                    for (final t in s.topTracks) t.track,
                  ], index: i);
                } else {
                  setState(() => _picked = i);
                }
              },
            ),
          ),
          if (_kind == _Kind.tracks) ...[
            const SizedBox(height: AppSpacing.sm),
            _MoreTile(label: l10n.homeTopTracksGo, onTap: widget.onMore),
          ],
          const SizedBox(height: AppSpacing.md),
          HomeCollapsible(
            label: listLabel,
            child: Column(
              children: [
                for (var i = 0; i < listed.length; i++)
                  TrackTile(
                    title: listed[i].title,
                    subtitle: listed[i].artist.isEmpty
                        ? l10n.unknownArtist
                        : listed[i].artist,
                    tone: toneFor(listed[i].id),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          child: StatNumber(
                            '${i + 1}',
                            size: 18,
                            color: _kind == _Kind.tracks && i == picked
                                ? context.palette.accent
                                : null,
                          ),
                        ),
                        ArtworkBox(
                          image: coverImageOf(
                            context,
                            CoverKey.track(listed[i].id),
                          ),
                          tone: toneFor(listed[i].id),
                        ),
                      ],
                    ),
                    trailing: Text(
                      l10n.playCount(counts[listed[i].id] ?? 0),
                      style: text.bodySmall,
                    ),
                    onTap: () => player.playQueue(listed, index: i),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 1등이 가운데에서 가장 높은 시상대 (2등 · 1등 · 3등 순). 칸마다 동그란 커버 · 이름 · 횟수.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.selected, this.onTap});

  final List<_Entry> entries;

  /// 고른 칸 (없으면 표시하지 않는다).
  final int selected;
  final ValueChanged<int>? onTap;

  static const _heights = [64.0, 44.0, 30.0];
  static const _art = [72.0, 56.0, 56.0];

  @override
  Widget build(BuildContext context) {
    // 보이는 순서: 2등 · 1등 · 3등
    const order = [1, 0, 2];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final i in order)
          Expanded(
            child: i < entries.length
                ? _Place(
                    rank: i,
                    entry: entries[i],
                    selected: selected == i,
                    onTap: () => onTap?.call(i),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

/// 시상대 한 칸. 포커스된 칸은 강조 색 + 커버가 살짝 커지고, 순위는 바뀌지 않는다.
class _Place extends StatelessWidget {
  const _Place({
    required this.rank,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final int rank;
  final _Entry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final art = _Podium._art[rank];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: selected ? 1.12 : 1,
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? p.accent : p.outline,
                  width: selected ? 3 : 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ArtworkBox(
                  image: coverImageOf(context, CoverKey.track(entry.cover.id)),
                  tone: toneFor(entry.cover.id),
                  size: art,
                  radius: art,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              entry.title,
              style: text.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Text(l10n.playCount(entry.count), style: text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            height: _Podium._heights[rank],
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? p.accent : p.surfaceHigh,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.sm),
              ),
            ),
            child: StatNumber(
              '${rank + 1}',
              size: 24,
              color: selected ? p.onAccent : p.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// 시상대 아래의 한 줄 타일 (예: TOP 100 보러가기 ›).
class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: AppSpacing.screen,
      child: Material(
        color: p.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.leaderboard_rounded, color: p.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.onSurfaceMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

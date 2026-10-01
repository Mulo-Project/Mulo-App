import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import 'home_parts.dart';

enum _Kind { tracks, artists, genres }

class _Entry {
  const _Entry(this.title, this.count, this.cover, this.onTap, {this.sub = ''});

  final String title;
  final String sub;
  final int count;

  /// 이미지를 빌려 올 대표 곡.
  final Track cover;
  final VoidCallback onTap;
}

/// ③ 많이 들은 곡: 곡 · 아티스트 · 장르 칩으로 고르고, 동그란 커버가 붙은 알약 카드를
/// 가로로 넘기며 본다 (두 줄). 카드를 누르면 그 곡 · 그 아티스트 · 그 장르의 곡을 재생한다.
/// 제목의 "›"는 많이 들은 곡 TOP 100 상세로 간다.
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

  List<_Entry> _entries(AppLocalizations l10n) {
    final s = widget.summary;
    final player = widget.player;
    return switch (_kind) {
      _Kind.tracks => [
        for (var i = 0; i < s.topTracks.length && i < 10; i++)
          _Entry(
            s.topTracks[i].track.title,
            s.topTracks[i].count,
            s.topTracks[i].track,
            () => player.playQueue([
              for (final t in s.topTracks) t.track,
            ], index: i),
            sub: s.topTracks[i].track.artist.isEmpty
                ? l10n.unknownArtist
                : s.topTracks[i].track.artist,
          ),
      ],
      _Kind.artists => [
        for (final a in s.stats.topArtists)
          _Entry(
            a.artist.isEmpty ? l10n.unknownArtist : a.artist,
            a.count,
            a.tracks.first,
            () => player.playQueue(a.tracks),
            sub: l10n.songCount(a.tracks.length),
          ),
      ],
      _Kind.genres => [
        for (final g in s.stats.topGenres)
          _Entry(
            g.genre,
            g.count,
            g.tracks.first,
            () => player.playQueue(g.tracks),
            sub: l10n.songCount(g.tracks.length),
          ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final entries = _entries(l10n);

    String label(_Kind k) => switch (k) {
      _Kind.tracks => l10n.homeChipTracks,
      _Kind.artists => l10n.homeChipArtists,
      _Kind.genres => l10n.homeChipGenres,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(l10n.homeTopTracks, onTap: widget.onMore),
        HomeChipRow(
          chips: [
            for (final k in _Kind.values)
              HomeChip(
                label: label(k),
                selected: _kind == k,
                onTap: () => setState(() => _kind = k),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          Padding(
            padding: AppSpacing.screen,
            child: Text(l10n.homeNoPlays, style: text.bodySmall),
          )
        else
          SizedBox(
            height: _Pill.height * 2 + AppSpacing.xs,
            child: GridView.builder(
              key: ValueKey(_kind),
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screen,
              itemCount: entries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 250,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
              ),
              itemBuilder: (context, i) =>
                  _Pill(rank: i + 1, entry: entries[i]),
            ),
          ),
      ],
    );
  }
}

/// 동그란 커버 + 순위 · 이름 · 재생 횟수가 붙은 알약 카드.
class _Pill extends StatelessWidget {
  const _Pill({required this.rank, required this.entry});

  static const height = 64.0;

  final int rank;
  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Material(
      color: p.surfaceHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry.onTap,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: ArtworkBox(
                image: coverImageOf(context, CoverKey.track(entry.cover.id)),
                tone: toneFor(entry.cover.id),
                size: height - AppSpacing.xxs * 2,
                radius: height,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entry.sub.isEmpty
                        ? l10n.playCount(entry.count)
                        : '${entry.sub} · ${l10n.playCount(entry.count)}',
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: StatNumber(
                '$rank',
                size: 20,
                color: rank == 1 ? p.accent : p.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

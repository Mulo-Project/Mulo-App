import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import 'home_format.dart';
import 'home_parts.dart';

/// ① 최근 들은 곡: 오늘 들은 횟수 · 시간을 그라데이션 배너로, 최근 곡은 큰 정사각 커버 캐러셀로.
class RecentSection extends StatelessWidget {
  const RecentSection({super.key, required this.summary, required this.player});

  final HomeSummary summary;
  final NowPlayingCubit player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final recent = summary.recent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(l10n.homeRecent),
        Padding(
          padding: AppSpacing.screen,
          child: _TodayBanner(
            plays: summary.todayPlays,
            listened: summary.todayListened,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (recent.isEmpty)
          Padding(
            padding: AppSpacing.screen,
            child: Text(l10n.homeNoPlays, style: text.bodySmall),
          )
        else
          SizedBox(
            height: 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screen,
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => _RecentCard(
                track: recent[i],
                onTap: () => player.playQueue(recent, index: i),
              ),
            ),
          ),
      ],
    );
  }
}

/// 오늘 들은 곡 횟수 · 재생 시간 배너 (테마 글로우 그라데이션).
class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.plays, required this.listened});

  final int plays;
  final Duration listened;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final label = text.bodySmall?.copyWith(
      color: p.onGlow.withValues(alpha: .8),
    );

    Widget stat(String value, String caption) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: label),
          const SizedBox(height: AppSpacing.xxs),
          StatNumber(value, size: 34, color: p.onGlow),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.glowPrimary,
        ),
      ),
      child: Row(
        children: [
          stat(l10n.playCount(plays), l10n.homeMetricPlays),
          stat(formatListened(l10n, listened), l10n.homeToday),
          Icon(Icons.headphones_rounded, size: 40, color: p.onGlow),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.track, required this.onTap});

  static const _size = 148.0;

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (d) =>
          showTrackMenu(context, track, globalPosition: d.globalPosition),
      child: SizedBox(
        width: _size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkBox(
              image: coverImageOf(context, CoverKey.track(track.id)),
              tone: toneFor(track.id),
              size: _size,
              radius: AppRadii.md,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              track.title,
              style: text.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              track.artist.isEmpty ? l10n.unknownArtist : track.artist,
              style: text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

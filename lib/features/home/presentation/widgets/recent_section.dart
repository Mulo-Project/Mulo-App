import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import 'home_format.dart';
import 'home_parts.dart';

/// ① 최근 들은 곡: 오늘 재생 횟수 · 시간을 굵은 머리말로, 그 아래 최근 재생한 곡 최대 10개를
/// 목록으로 (접을 수 있다).
class RecentSection extends StatelessWidget {
  const RecentSection({super.key, required this.summary, required this.player});

  final HomeSummary summary;
  final NowPlayingCubit player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final recent = summary.recent.take(10).toList();

    Widget stat(String value, String caption) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatNumber(value, size: 26),
          const SizedBox(height: AppSpacing.xxs),
          Text(caption, style: text.bodySmall),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(l10n.homeRecent),
        Padding(
          padding: AppSpacing.screen,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  stat(
                    l10n.playCount(summary.todayPlays),
                    l10n.homeMetricPlays,
                  ),
                  stat(
                    formatListened(l10n, summary.todayListened),
                    l10n.homeToday,
                  ),
                  Icon(AppIcons.headphones, size: 24, color: p.accent),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HomeCollapsible(
          label: l10n.homeRecentList,
          child: recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(l10n.homeNoPlays, style: text.bodySmall),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      TrackTile(
                        title: recent[i].title,
                        subtitle: recent[i].artist.isEmpty
                            ? l10n.unknownArtist
                            : recent[i].artist,
                        tone: toneFor(recent[i].id),
                        color: coverColorOf(
                          context,
                          CoverKey.track(recent[i].id),
                        ),
                        artwork: coverImageOf(
                          context,
                          CoverKey.track(recent[i].id),
                        ),
                        trailing: TrackMoreButton(track: recent[i]),
                        onTap: () => player.playQueue(recent, index: i),
                        onMenu: (pos) => showTrackMenu(
                          context,
                          recent[i],
                          globalPosition: pos,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

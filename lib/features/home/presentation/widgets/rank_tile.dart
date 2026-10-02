import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../../domain/entities/home_summary.dart';

/// 많이 들은 곡 한 줄: 순위 · 이미지 · 제목 · 재생 횟수.
class RankTile extends StatelessWidget {
  const RankTile({
    super.key,
    required this.rank,
    required this.item,
    this.onTap,
  });

  final int rank;
  final TrackPlays item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = item.track;
    return TrackTile(
      title: t.title,
      subtitle: t.artist.isEmpty ? l10n.unknownArtist : t.artist,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: StatNumber(
              '$rank',
              size: 22,
              color: rank == 1 ? context.palette.accent : null,
            ),
          ),
          ArtworkBox(
            image: coverImageOf(context, CoverKey.track(t.id)),
            tone: toneFor(t.id),
            color: coverColorOf(context, CoverKey.track(t.id)),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.playCount(item.count),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TrackMoreButton(track: t),
        ],
      ),
      onTap: onTap,
      onMenu: (pos) => showTrackMenu(context, t, globalPosition: pos),
    );
  }
}

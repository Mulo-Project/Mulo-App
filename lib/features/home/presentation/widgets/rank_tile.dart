import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/presentation/widgets/track_list_tile.dart'
    show TrackSelection, selectionMark;
import '../../../library/presentation/widgets/track_menu.dart';
import '../../domain/entities/home_summary.dart';

/// 많이 들은 곡 한 줄: 순위 · 이미지 · 제목 · 재생 횟수.
class RankTile extends StatelessWidget {
  const RankTile({
    super.key,
    required this.rank,
    required this.item,
    this.onTap,
    this.selection,
  });

  final int rank;
  final TrackPlays item;
  final VoidCallback? onTap;

  /// 있으면 길게 눌러 선택 모드에 들어가고, 선택 모드에서는 누르면 고르거나 푼다.
  final TrackSelection? selection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = item.track;
    final sel = selection;
    final picking = sel != null && sel.active;
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
      trailing: picking
          ? selectionMark(context, sel)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.playCount(item.count),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TrackMoreButton(track: t),
              ],
            ),
      onTap: picking ? sel.onToggle : onTap,
      onLongPress: sel?.onToggle,
      onMenu: sel != null
          ? null
          : (pos) => showTrackMenu(context, t, globalPosition: pos),
    );
  }
}

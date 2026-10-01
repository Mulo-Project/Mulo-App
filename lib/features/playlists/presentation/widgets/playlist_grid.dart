import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/playlist.dart';
import 'playlist_card.dart';

/// 재생목록 카드를 2열로 늘어놓는다. 재생목록 탭과 담기 선택 화면에서 같이 쓴다.
/// [cardBuilder]로 카드를 바꿀 수 있고, 안 주면 둘러보기 카드를 만든다.
class PlaylistGrid extends StatelessWidget {
  const PlaylistGrid({super.key, required this.lists, this.cardBuilder});

  final List<Playlist> lists;
  final Widget Function(BuildContext context, Playlist playlist)? cardBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final pl in lists)
              SizedBox(
                width: w,
                child:
                    cardBuilder?.call(context, pl) ??
                    PlaylistCard(playlist: pl),
              ),
          ],
        );
      },
    );
  }
}

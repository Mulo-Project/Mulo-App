import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/home_summary.dart';

/// 장르 · 아티스트 · 앨범 순위: 옆으로 넘기는 페이지 세 장 + 점 표시.
class RankingPages extends StatefulWidget {
  const RankingPages({super.key, required this.stats});

  final ListeningStats stats;

  @override
  State<RankingPages> createState() => _RankingPagesState();
}

class _RankingPagesState extends State<RankingPages> {
  static const _rows = 5;
  static const _rowHeight = 40.0;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final s = widget.stats;

    final pages = [
      (l10n.homeTopGenre, [for (final g in s.topGenres) (g.genre, g.count)]),
      (
        l10n.homeTopArtist,
        [
          for (final a in s.topArtists)
            (a.artist.isEmpty ? l10n.unknownArtist : a.artist, a.count),
        ],
      ),
      (l10n.homeTopAlbum, [for (final a in s.topAlbums) (a.album, a.count)]),
    ];

    return Column(
      children: [
        SizedBox(
          height: 36 + _rows * _rowHeight,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final (title, items) in pages)
                _RankingPage(title: title, items: items),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < pages.length; i++)
              AnimatedContainer(
                duration: AppMotion.medium,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: ShapeDecoration(
                  color: i == _page ? p.accent : p.outline,
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RankingPage extends StatelessWidget {
  const _RankingPage({required this.title, required this.items});

  final String title;
  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: text.titleSmall),
            ),
          ),
          if (items.isEmpty)
            Text(l10n.homeNoPlays, style: text.bodySmall)
          else
            for (var i = 0; i < items.length; i++)
              SizedBox(
                height: _RankingPagesState._rowHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: StatNumber(
                        '${i + 1}',
                        size: 20,
                        color: i == 0 ? p.accent : null,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        items[i].$1,
                        style: text.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(l10n.playCount(items[i].$2), style: text.bodySmall),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import 'home_parts.dart';

String recommendTitle(AppLocalizations l10n, RecommendedPlaylist p) =>
    switch (p.kind) {
      RecommendedKind.artistMix => l10n.homeRecArtist(p.label),
      RecommendedKind.genreMix => l10n.homeRecGenre(p.label),
      RecommendedKind.unheard => l10n.homeRecUnheard,
      RecommendedKind.newest => l10n.homeRecNewest,
    };

/// ④ 추천 플레이리스트: 한 페이지에 2열 × 2줄, 옆으로 넘긴다.
/// 한 칸은 커버 · 이름 · 곡 수 · 재생 버튼이고, 누르면 묶음 전체를 재생한다.
class RecommendSection extends StatefulWidget {
  const RecommendSection({
    super.key,
    required this.playlists,
    required this.player,
  });

  final List<RecommendedPlaylist> playlists;
  final NowPlayingCubit player;

  static const _perPage = 4;
  static const _rowHeight = 76.0;

  @override
  State<RecommendSection> createState() => _RecommendSectionState();
}

class _RecommendSectionState extends State<RecommendSection> {
  static const _perPage = RecommendSection._perPage;
  static const _rowHeight = RecommendSection._rowHeight;

  final _controller = PageController(viewportFraction: .94);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final playlists = widget.playlists;
    final player = widget.player;
    final pages = (playlists.length / _perPage).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(l10n.homeRecommendations),
        if (playlists.isEmpty)
          Padding(
            padding: AppSpacing.screen,
            child: Text(l10n.homeNoRecommendations, style: text.bodySmall),
          )
        else
          SizedBox(
            height: _rowHeight * 2 + AppSpacing.xs,
            child: PageView.builder(
              padEnds: false,
              controller: _controller,
              itemCount: pages,
              itemBuilder: (context, page) {
                final items = playlists
                    .skip(page * _perPage)
                    .take(_perPage)
                    .toList();
                Widget cell(int i) => Expanded(
                  child: i < items.length
                      ? _Cell(
                          playlist: items[i],
                          onPlay: () => player.playQueue(items[i].tracks),
                        )
                      : const SizedBox.shrink(),
                );
                return Padding(
                  padding: EdgeInsets.only(
                    left: page == 0 ? AppSpacing.md : AppSpacing.xs,
                    right: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      for (var row = 0; row < 2; row++) ...[
                        if (row > 0) const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          height: _rowHeight,
                          child: Row(
                            children: [
                              cell(row * 2),
                              const SizedBox(width: AppSpacing.xs),
                              cell(row * 2 + 1),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.playlist, required this.onPlay});

  final RecommendedPlaylist playlist;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final first = playlist.tracks.first;
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Row(
        children: [
          ArtworkBox(
            image: coverImageOf(context, CoverKey.track(first.id)),
            tone: toneFor(first.id),
            size: 56,
            radius: AppRadii.sm,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendTitle(l10n, playlist),
                  style: text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.songCount(playlist.tracks.length),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill_rounded, size: 32, color: p.accent),
        ],
      ),
    );
  }
}

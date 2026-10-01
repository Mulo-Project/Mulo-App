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
      RecommendedKind.rediscover => l10n.homeRecRediscover,
      RecommendedKind.unheard => l10n.homeRecUnheard,
      RecommendedKind.newest => l10n.homeRecNewest,
    };

/// ④ 추천 플레이리스트: 한 페이지가 추천 후보 하나이고, 옆으로 넘기면 다른 후보가 나온다.
/// 페이지마다 곡 최대 10개를 목록으로 보여 주고, "전체 재생"은 그 후보의 곡 전부를 재생한다.
class RecommendSection extends StatefulWidget {
  const RecommendSection({
    super.key,
    required this.playlists,
    required this.player,
  });

  final List<RecommendedPlaylist> playlists;
  final NowPlayingCubit player;

  @override
  State<RecommendSection> createState() => _RecommendSectionState();
}

class _RecommendSectionState extends State<RecommendSection> {
  static const _preview = 10;
  static const _rowHeight = 64.0;
  static const _headerHeight = 56.0;

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
    final text = Theme.of(context).textTheme;
    final playlists = widget.playlists;
    final player = widget.player;

    final rows = playlists.fold(
      0,
      (m, pl) => pl.tracks.length > m ? pl.tracks.length : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(l10n.homeRecommendations),
        if (playlists.isEmpty)
          Padding(
            padding: AppSpacing.screen,
            child: Text(l10n.homeNoRecommendations, style: text.bodySmall),
          )
        else ...[
          SizedBox(
            height:
                _headerHeight +
                (rows > _preview ? _preview : rows) * _rowHeight,
            child: PageView.builder(
              controller: _controller,
              itemCount: playlists.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final pl = playlists[i];
                final shown = pl.tracks.take(_preview).toList();
                // coverImageOf는 context.select를 쓰므로 목록 빌더 밖의 Builder 안에서 부른다.
                return Builder(
                  builder: (context) => Column(
                    children: [
                      SizedBox(
                        height: _headerHeight,
                        child: Padding(
                          padding: AppSpacing.screen,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recommendTitle(l10n, pl),
                                      style: text.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      l10n.songCount(pl.tracks.length),
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              PillButton(
                                compact: true,
                                icon: Icons.play_arrow_rounded,
                                label: l10n.actionPlayAll,
                                onPressed: () => player.playQueue(pl.tracks),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (var j = 0; j < shown.length; j++)
                        SizedBox(
                          height: _rowHeight,
                          child: TrackTile(
                            title: shown[j].title,
                            subtitle: shown[j].artist.isEmpty
                                ? l10n.unknownArtist
                                : shown[j].artist,
                            tone: toneFor(shown[j].id),
                            artwork: coverImageOf(
                              context,
                              CoverKey.track(shown[j].id),
                            ),
                            onTap: () => player.playQueue(pl.tracks, index: j),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < playlists.length; i++)
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
      ],
    );
  }
}

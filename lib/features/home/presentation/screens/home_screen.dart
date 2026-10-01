import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import '../bloc/home_bloc.dart';
import '../widgets/home_format.dart';
import '../widgets/play_history_section.dart';
import '../widgets/rank_tile.dart';
import '../widgets/ranking_pages.dart';
import 'top_tracks_screen.dart';

/// 홈의 많이 들은 곡 미리보기 곡 수 (전체는 상세 화면에서 최대 100곡).
const _topPreview = 10;

/// 홈 (상세 기능: 많이 들은 곡 순위 · 청취 분석 · 추천 목록 · 최근 재생).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.libraryRoute = '/library'});

  /// 보관함이 비었을 때 "보관함으로" 버튼이 가는 곳.
  final String libraryRoute;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
    child: _HomeView(libraryRoute: libraryRoute),
  );
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.libraryRoute});

  final String libraryRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HomeBloc>().state;
    final s = state.summary;
    final player = context.read<NowPlayingCubit>();
    final preview = s.topTracks.take(_topPreview).toList();

    final body = <Widget>[
      if (state.loaded && s.libraryEmpty)
        Padding(
          padding: AppSpacing.screen,
          child: _EmptyState(
            title: l10n.homeEmptyLibraryTitle,
            body: l10n.homeEmptyLibraryBody,
            action: l10n.homeGoLibrary,
            onAction: () => context.go(libraryRoute),
          ),
        )
      else ...[
        // 1. 최근 들은 곡: 오늘 들은 시간 (펼치면 최근 재생한 곡)
        SectionPanel(
          icon: Icons.history_rounded,
          title: l10n.homeRecent,
          child: ExpandSection(
            header: _TodaySummary(
              listened: s.todayListened,
              plays: s.todayPlays,
            ),
            child: _RecentTracks(tracks: s.recent, player: player),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 2. 날짜별 청취 데이터: 기간 · 그래프 · 장르/아티스트/앨범 순위
        SectionPanel(
          icon: Icons.show_chart_rounded,
          title: l10n.homeHistory,
          tone: GlowTone.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.screen,
                child: SegmentedPills<HomePeriod>(
                  expand: true,
                  values: HomePeriod.values,
                  selected: state.period,
                  labelOf: (p) => switch (p) {
                    HomePeriod.week => l10n.homePeriodWeek,
                    HomePeriod.month => l10n.homePeriodMonth,
                    HomePeriod.all => l10n.homePeriodAll,
                  },
                  onChanged: (p) =>
                      context.read<HomeBloc>().add(HomePeriodChanged(p)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: AppSpacing.screen,
                child: PlayHistorySection(state: state),
              ),
              const SizedBox(height: AppSpacing.lg),
              RankingPages(stats: s.stats),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 3. 많이 들은 곡: 펼치면 TOP 10, 더 보면 TOP 100 상세
        SectionPanel(
          icon: Icons.leaderboard_rounded,
          title: l10n.homeTopTracks,
          tone: GlowTone.tertiary,
          collapsible: true,
          child: s.topTracks.isEmpty
              ? _Muted(l10n.homeNoPlays)
              : Column(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      RankTile(
                        rank: i + 1,
                        item: preview[i],
                        onTap: () => player.playQueue([
                          for (final t in s.topTracks) t.track,
                        ], index: i),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        0,
                      ),
                      child: Row(
                        children: [
                          PillButton(
                            compact: true,
                            icon: Icons.play_arrow_rounded,
                            label: l10n.actionPlayAll,
                            onPressed: () => player.playQueue([
                              for (final t in s.topTracks) t.track,
                            ]),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          PillButton(
                            compact: true,
                            variant: PillVariant.tonal,
                            label: l10n.homeTopTracksMore,
                            onPressed: () => context.push(
                              topTracksLocation(state.period, state.month),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 4. 추천 재생목록: 옆으로 넘기며 고르면 통째로 재생
        SectionPanel(
          icon: Icons.auto_awesome_rounded,
          title: l10n.homeRecommendations,
          child: s.recommendedPlaylists.isEmpty
              ? _Muted(l10n.homeNoRecommendations)
              : SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpacing.screen,
                    itemCount: s.recommendedPlaylists.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) => _RecommendCard(
                      playlist: s.recommendedPlaylists[i],
                      onTap: () =>
                          player.playQueue(s.recommendedPlaylists[i].tracks),
                    ),
                  ),
                ),
        ),
      ],
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            large: true,
            title: l10n.navHome,
            subtitle: l10n.homeSubtitle,
          ),
          ...body,
        ],
      ),
    );
  }
}

String _artist(AppLocalizations l10n, Track t) =>
    t.artist.isEmpty ? l10n.unknownArtist : t.artist;

/// 오늘 들은 시간 (재생 기록에서 계산).
class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.listened, required this.plays});

  final Duration listened;
  final int plays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeToday, style: text.bodySmall),
              const SizedBox(height: AppSpacing.xxs),
              StatNumber(formatListened(l10n, listened), size: 36),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                plays == 0 ? l10n.homeTodayNone : l10n.homeTodayPlays(plays),
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        Icon(Icons.headphones_rounded, size: 36, color: context.palette.accent),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

/// 오늘 들은 시간을 펼치면 보이는, 최근 재생한 곡.
class _RecentTracks extends StatelessWidget {
  const _RecentTracks({required this.tracks, required this.player});

  final List<Track> tracks;
  final NowPlayingCubit player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (tracks.isEmpty)
          _Muted(l10n.homeNoPlays)
        else
          for (var i = 0; i < tracks.length; i++)
            TrackTile(
              title: tracks[i].title,
              subtitle: _artist(l10n, tracks[i]),
              tone: toneFor(tracks[i].id),
              artwork: coverImageOf(context, CoverKey.track(tracks[i].id)),
              trailing: TrackMoreButton(track: tracks[i]),
              onTap: () => player.playQueue(tracks, index: i),
              onMenu: (pos) =>
                  showTrackMenu(context, tracks[i], globalPosition: pos),
            ),
      ],
    );
  }
}

String _recommendTitle(AppLocalizations l10n, RecommendedPlaylist p) =>
    switch (p.kind) {
      RecommendedKind.artistMix => l10n.homeRecArtist(p.label),
      RecommendedKind.genreMix => l10n.homeRecGenre(p.label),
      RecommendedKind.unheard => l10n.homeRecUnheard,
      RecommendedKind.newest => l10n.homeRecNewest,
    };

/// 추천 재생목록 카드: 누르면 묶음 전체를 대기열로 재생한다.
class _RecommendCard extends StatelessWidget {
  const _RecommendCard({required this.playlist, this.onTap});

  final RecommendedPlaylist playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final first = playlist.tracks.first;
    return SizedBox(
      width: 132,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkBox(
              image: coverImageOf(context, CoverKey.track(first.id)),
              tone: toneFor(first.id),
              size: 132,
              radius: AppRadii.md,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _recommendTitle(l10n, playlist),
              style: text.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              l10n.songCount(playlist.tracks.length),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: 40,
            color: context.palette.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: action,
            icon: Icons.library_music_rounded,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

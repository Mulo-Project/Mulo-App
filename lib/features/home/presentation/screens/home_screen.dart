import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import '../bloc/home_bloc.dart';

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

    final body = <Widget>[
      if (state.loaded && s.libraryEmpty)
        Padding(
          padding: AppSpacing.screen,
          child: _EmptyCard(
            title: l10n.homeEmptyLibraryTitle,
            body: l10n.homeEmptyLibraryBody,
            action: l10n.homeGoLibrary,
            onAction: () => context.go(libraryRoute),
          ),
        )
      else ...[
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
          child: _StatsCard(stats: s.stats),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(l10n.homeTopTracks),
        if (s.topTracks.isEmpty)
          _Muted(l10n.homeNoPlays)
        else
          for (var i = 0; i < s.topTracks.length; i++)
            _RankTile(
              rank: i + 1,
              item: s.topTracks[i],
              onTap: () => player.playQueue([
                for (final t in s.topTracks) t.track,
              ], index: i),
            ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(l10n.homeRecommendations),
        if (s.recommendations.isEmpty)
          _Muted(l10n.homeNoRecommendations)
        else
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screen,
              itemCount: s.recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => _RecommendCard(
                track: s.recommendations[i],
                onTap: () => player.playQueue(s.recommendations, index: i),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(l10n.homeRecent),
        if (s.recent.isEmpty)
          _Muted(l10n.homeNoPlays)
        else
          for (var i = 0; i < s.recent.length; i++)
            TrackTile(
              title: s.recent[i].title,
              subtitle: _artist(l10n, s.recent[i]),
              tone: toneFor(s.recent[i].id),
              artwork: coverImageOf(context, CoverKey.track(s.recent[i].id)),
              onTap: () => player.playQueue(s.recent, index: i),
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final topArtist = stats.topArtists.isEmpty
        ? '–'
        : (stats.topArtists.first.artist.isEmpty
              ? l10n.unknownArtist
              : stats.topArtists.first.artist);

    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatNumber(value, size: 40),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: text.bodySmall),
        ],
      ),
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeStats, style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              stat('${stats.plays}', l10n.homeStatPlays),
              stat('${stats.uniqueTracks}', l10n.homeStatTracks),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.homeTopArtist, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            topArtist,
            style: text.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.item, this.onTap});

  final int rank;
  final TrackPlays item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = item.track;
    return TrackTile(
      title: t.title,
      subtitle: _artist(l10n, t),
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
          ),
        ],
      ),
      trailing: Text(
        l10n.playCount(item.count),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}

class _RecommendCard extends StatelessWidget {
  const _RecommendCard({required this.track, this.onTap});

  final Track track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 132,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkBox(
              image: coverImageOf(context, CoverKey.track(track.id)),
              tone: toneFor(track.id),
              size: 132,
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
              _artist(context.l10n, track),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
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
    return GlassCard(
      tone: GlowTone.secondary,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.graphic_eq_rounded, size: 40),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
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

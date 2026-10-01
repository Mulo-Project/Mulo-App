import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/home_summary.dart';
import '../bloc/home_bloc.dart';
import '../widgets/rank_tile.dart';

/// 상세 화면 경로 (홈 탭 안): 기간과 (이번 달이면) 달을 쿼리로 넘긴다.
String topTracksLocation(HomePeriod period, DateTime? month) => Uri(
  path: '/home/top-tracks',
  queryParameters: {
    'period': period.name,
    if (period == HomePeriod.month && month != null)
      'month': '${month.year}-${month.month}',
  },
).toString();

/// [topTracksLocation]의 쿼리에서 화면을 만든다.
TopTracksScreen topTracksScreenFrom(Map<String, String> query) {
  final period =
      HomePeriod.values.asNameMap()[query['period']] ?? HomePeriod.week;
  final parts = (query['month'] ?? '').split('-');
  final year = int.tryParse(parts.first);
  final mon = parts.length == 2 ? int.tryParse(parts[1]) : null;
  return TopTracksScreen(
    period: period,
    month: year == null || mon == null ? null : DateTime(year, mon),
  );
}

/// 많이 들은 곡 상세: 고른 기간의 TOP 100. 전체를 재생목록처럼 재생할 수 있다.
class TopTracksScreen extends StatelessWidget {
  const TopTracksScreen({super.key, required this.period, this.month});

  final HomePeriod period;
  final DateTime? month;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        sl<HomeBloc>()..add(HomeStarted(period: period, month: month)),
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HomeBloc>().state;
    final tracks = [for (final t in state.summary.topTracks) t.track];
    final player = context.read<NowPlayingCubit>();
    final month = state.month;

    final period = switch (state.period) {
      HomePeriod.week => l10n.homePeriodWeek,
      HomePeriod.month =>
        month == null
            ? l10n.homePeriodMonth
            : l10n.homeMonthLabel(month.year, month.month),
      HomePeriod.all => l10n.homePeriodAll,
    };

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            title: l10n.homeTopTracksTitle,
            subtitle: period,
            leading: CircleIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: l10n.actionBack,
              onPressed: () => context.pop(),
            ),
          ),
          if (state.loaded && tracks.isEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.homeNoPlays,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else ...[
            Padding(
              padding: AppSpacing.screen,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PillButton(
                  icon: Icons.play_arrow_rounded,
                  label: l10n.actionPlayAll,
                  onPressed: tracks.isEmpty
                      ? null
                      : () => player.playQueue(tracks),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < state.summary.topTracks.length; i++)
              RankTile(
                rank: i + 1,
                item: state.summary.topTracks[i],
                onTap: () => player.playQueue(tracks, index: i),
              ),
          ],
        ],
      ),
    );
  }
}

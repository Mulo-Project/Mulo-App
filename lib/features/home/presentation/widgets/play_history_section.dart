import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/home_summary.dart';
import '../bloc/home_bloc.dart';
import 'home_format.dart';
import 'month_picker_sheet.dart';

enum _Metric { plays, time }

/// 재생 기록: 이번 주 · 이번 달은 꺾은선 그래프(재생 횟수 또는 시간),
/// 이번 달은 달력으로 달을 고른다. 전체는 들은 날 · 총 재생 시간 등 숫자로 보여 준다.
class PlayHistorySection extends StatefulWidget {
  const PlayHistorySection({super.key, required this.state, this.now});

  final HomeState state;

  /// 기준 시각 (테스트용). 없으면 지금.
  final DateTime? now;

  @override
  State<PlayHistorySection> createState() => _PlayHistorySectionState();
}

class _PlayHistorySectionState extends State<PlayHistorySection> {
  _Metric _metric = _Metric.plays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final state = widget.state;
    final summary = state.summary;
    final now = widget.now ?? DateTime.now();
    final month = state.month ?? DateTime(now.year, now.month);

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (state.period == HomePeriod.month)
          PillButton(
            compact: true,
            variant: PillVariant.tonal,
            icon: Icons.calendar_month_rounded,
            label: l10n.homeMonthLabel(month.year, month.month),
            onPressed: () async {
              final bloc = context.read<HomeBloc>();
              final picked = await showMonthPickerSheet(
                context,
                selected: month,
                now: now,
              );
              if (picked != null) bloc.add(HomeMonthChanged(picked));
            },
          ),
      ],
    );

    final Widget body;
    if (state.period == HomePeriod.all) {
      body = _AllStats(stats: summary.stats);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedPills<_Metric>(
            expand: true,
            values: _Metric.values,
            selected: _metric,
            labelOf: (m) => switch (m) {
              _Metric.plays => l10n.homeMetricPlays,
              _Metric.time => l10n.homeMetricTime,
            },
            onChanged: (m) => setState(() => _metric = m),
          ),
          const SizedBox(height: AppSpacing.md),
          if (summary.stats.plays == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                l10n.homeChartNone,
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else
            _Chart(
              daily: summary.daily,
              metric: _metric,
              weekly: state.period == HomePeriod.week,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.period == HomePeriod.month) ...[
          header,
          const SizedBox(height: AppSpacing.sm),
        ],
        body,
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.daily,
    required this.metric,
    required this.weekly,
  });

  final List<DayListening> daily;
  final _Metric metric;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    double value(DayListening d) => switch (metric) {
      _Metric.plays => d.plays.toDouble(),
      _Metric.time => d.listened.inSeconds / 60,
    };
    final top = daily.fold(0.0, (a, d) => value(d) > a ? value(d) : a);
    final maxLabel = switch (metric) {
      _Metric.plays => l10n.playCount(top.round()),
      _Metric.time => formatListened(l10n, Duration(minutes: top.round())),
    };

    return AppLineChart(
      points: [
        for (final d in daily)
          LineChartPoint(
            value(d),
            label: weekly ? '${d.day.month}/${d.day.day}' : '${d.day.day}',
          ),
      ],
      maxLabel: maxLabel,
    );
  }
}

/// 전체 기간: 들은 날 · 총 재생 시간 · 총 재생 · 들은 곡.
class _AllStats extends StatelessWidget {
  const _AllStats({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatNumber(value, size: 28),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: text.bodySmall),
        ],
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            stat(l10n.homeAllDaysValue(stats.daysListened), l10n.homeAllDays),
            stat(formatListened(l10n, stats.listened), l10n.homeAllTime),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            stat(l10n.playCount(stats.plays), l10n.homeAllPlays),
            stat(l10n.songCount(stats.uniqueTracks), l10n.homeAllTracks),
          ],
        ),
      ],
    );
  }
}

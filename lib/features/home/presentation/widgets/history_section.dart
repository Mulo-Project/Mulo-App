import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/home_summary.dart';
import 'home_format.dart';
import 'home_parts.dart';

enum _View { week, month, all }

enum _Metric { plays, time }

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// ② 날짜별 청취 데이터: 주간 · 월간 · 전체를 칩으로 고른다.
/// 주간 · 월간은 같은 모양의 어두운 판 위 꺾은선 그래프이고, 월간은 년 · 월 버튼을 눌러
/// 팝업 메뉴에서 고른다 (앱을 쓰기 시작한 달 이전은 없다). 숫자 칸(재생 수 / 시간)을 눌러
/// 그래프 값을 바꾼다. 전체는 판 없이 큰 숫자로 보여 준다.
class HistorySection extends StatefulWidget {
  const HistorySection({
    super.key,
    required this.summary,
    this.joinedAt,
    this.now,
  });

  final HomeSummary summary;

  /// 앱을 처음 쓴 날. 이 달 이전은 월간에서 고를 수 없다. 모르면 이번 달만.
  final DateTime? joinedAt;

  /// 기준 시각 (테스트용). 없으면 지금.
  final DateTime? now;

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  _View _view = _View.week;
  _Metric _metric = _Metric.plays;

  /// 월간에서 보는 달 (1일). 처음에는 이번 달.
  DateTime? _month;

  DateTime get _now => widget.now ?? DateTime.now();
  DateTime get _lastMonth => DateTime(_now.year, _now.month);
  DateTime get _firstMonth {
    final j = widget.joinedAt ?? _now;
    final first = DateTime(j.year, j.month);
    return first.isAfter(_lastMonth) ? _lastMonth : first;
  }

  DateTime get _shown {
    final m = _month ?? _lastMonth;
    if (m.isBefore(_firstMonth)) return _firstMonth;
    if (m.isAfter(_lastMonth)) return _lastMonth;
    return m;
  }

  Future<void> _pickYear(BuildContext anchor) async {
    final l10n = context.l10n;
    final shown = _shown;
    final year = await showAppMenu<int>(
      anchor,
      items: [
        for (var y = _lastMonth.year; y >= _firstMonth.year; y--)
          AppMenuItem(
            value: y,
            icon: Icons.event_rounded,
            label: l10n.homeYearLabel(y),
            selected: y == shown.year,
          ),
      ],
    );
    if (year == null || !mounted) return;
    // 고른 해에 같은 달이 없으면 가까운 달로 맞춘다.
    var next = DateTime(year, shown.month);
    if (next.isBefore(_firstMonth)) next = _firstMonth;
    if (next.isAfter(_lastMonth)) next = _lastMonth;
    setState(() => _month = next);
  }

  Future<void> _pickMonth(BuildContext anchor) async {
    final l10n = context.l10n;
    final shown = _shown;
    final month = await showAppMenu<int>(
      anchor,
      items: [
        for (var m = 1; m <= 12; m++)
          if (!DateTime(shown.year, m).isBefore(_firstMonth) &&
              !DateTime(shown.year, m).isAfter(_lastMonth))
            AppMenuItem(
              value: m,
              icon: Icons.calendar_month_rounded,
              label: l10n.homeMonthShort(m),
              selected: m == shown.month,
            ),
      ],
    );
    if (month == null || !mounted) return;
    setState(() => _month = DateTime(shown.year, month));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final s = widget.summary;
    final today = _day(_now);

    String label(_View v) => switch (v) {
      _View.week => l10n.homePeriodWeek,
      _View.month => l10n.homePeriodMonth,
      _View.all => l10n.homePeriodAll,
    };

    Widget board(Widget caption, List<DayListening> days, bool weekly) =>
        Padding(
          padding: AppSpacing.screen,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  caption,
                  const SizedBox(height: AppSpacing.xs),
                  _Block(
                    days: days,
                    metric: _metric,
                    onMetric: (m) => setState(() => _metric = m),
                    weekly: weekly,
                  ),
                ],
              ),
            ),
          ),
        );

    final Widget body;
    switch (_view) {
      case _View.week:
        final week = s.range(today.subtract(const Duration(days: 6)), today);
        body = board(
          Text(
            '${week.first.day.month}/${week.first.day.day} ~ ${today.month}/${today.day}',
            style: text.bodySmall,
          ),
          week,
          true,
        );
      case _View.month:
        final shown = _shown;
        final last = shown == _lastMonth
            ? today
            : DateTime(shown.year, shown.month + 1, 0);
        body = board(
          Row(
            children: [
              Builder(
                builder: (b) => _PeriodButton(
                  label: l10n.homeYearLabel(shown.year),
                  onTap: () => _pickYear(b),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Builder(
                builder: (b) => _PeriodButton(
                  label: l10n.homeMonthShort(shown.month),
                  onTap: () => _pickMonth(b),
                ),
              ),
            ],
          ),
          s.range(shown, last),
          false,
        );
      case _View.all:
        body = _AllStats(stats: s.stats, since: widget.joinedAt);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(l10n.homeHistory),
        HomeChipRow(
          chips: [
            for (final v in _View.values)
              HomeChip(
                label: label(v),
                selected: _view == v,
                onTap: () => setState(() => _view = v),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        body,
      ],
    );
  }
}

/// 기간 글자를 강조한 작은 버튼 (눌러서 년 · 월 팝업 메뉴를 연다).
class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.accent.withValues(alpha: .16),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: p.accent, fontWeight: FontWeight.w700),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 20, color: p.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// 한 기간의 숫자 두 칸(재생 수 · 재생 시간) + 꺾은선 그래프.
/// 숫자 칸을 누르면 그래프가 그 값으로 바뀐다.
class _Block extends StatelessWidget {
  const _Block({
    required this.days,
    required this.metric,
    required this.onMetric,
    required this.weekly,
  });

  final List<DayListening> days;
  final _Metric metric;
  final ValueChanged<_Metric> onMetric;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final plays = days.fold(0, (a, d) => a + d.plays);
    final time = days.fold(Duration.zero, (a, d) => a + d.listened);

    double value(DayListening d) => switch (metric) {
      _Metric.plays => d.plays.toDouble(),
      _Metric.time => d.listened.inSeconds / 60,
    };
    final top = days.fold(0.0, (a, d) => value(d) > a ? value(d) : a);
    final maxLabel = switch (metric) {
      _Metric.plays => l10n.playCount(top.round()),
      _Metric.time => formatListened(l10n, Duration(minutes: top.round())),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _StatChoice(
              value: l10n.playCount(plays),
              label: l10n.homeMetricPlays,
              selected: metric == _Metric.plays,
              onTap: () => onMetric(_Metric.plays),
            ),
            _StatChoice(
              value: formatListened(l10n, time),
              label: l10n.homeMetricTime,
              selected: metric == _Metric.time,
              onTap: () => onMetric(_Metric.time),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (plays == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              l10n.homeChartNone,
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          )
        else
          AppLineChart(
            points: [
              for (final d in days)
                LineChartPoint(
                  value(d),
                  label: weekly
                      ? '${d.day.month}/${d.day.day}'
                      : '${d.day.day}',
                ),
            ],
            maxLabel: maxLabel,
          ),
      ],
    );
  }
}

/// 누르면 그래프 값이 되는 숫자 칸. 고른 칸은 강조 색 숫자 + 아래 막대.
class _StatChoice extends StatelessWidget {
  const _StatChoice({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatNumber(
                  value,
                  size: 26,
                  color: selected ? p.accent : p.onSurfaceMuted,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(label, style: text.bodySmall),
                const SizedBox(height: AppSpacing.xxs),
                AnimatedContainer(
                  duration: AppMotion.medium,
                  height: 3,
                  width: selected ? 28 : 0,
                  decoration: ShapeDecoration(
                    color: p.accent,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 전체: 판 없이 큰 숫자 한 줄(총 재생 시간) + 얇은 선 아래 재생 수 · 들은 날.
class _AllStats extends StatelessWidget {
  const _AllStats({required this.stats, this.since});

  final ListeningStats stats;
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    Widget col(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatNumber(value, size: 26),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: text.bodySmall),
        ],
      ),
    );

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (since != null)
            Text(
              l10n.homeAllSince(l10n.homeMonthLabel(since!.year, since!.month)),
              style: text.bodySmall,
            ),
          const SizedBox(height: AppSpacing.xxs),
          StatNumber(formatListened(l10n, stats.listened), size: 52),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.homeAllTime, style: text.bodySmall),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: p.outline),
          ),
          Row(
            children: [
              col(l10n.playCount(stats.plays), l10n.homeAllPlays),
              col(l10n.homeAllDaysValue(stats.daysListened), l10n.homeAllDays),
            ],
          ),
        ],
      ),
    );
  }
}

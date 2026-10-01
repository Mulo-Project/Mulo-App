import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/home_summary.dart';
import 'home_format.dart';
import 'home_parts.dart';
import 'month_picker_dialog.dart';

enum _View { week, month, all }

enum _Metric { plays, time }

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// ② 날짜별 청취 데이터: 주간 · 월간 · 전체를 칩으로 고르고, 어두운 판 위에 그래프를 그린다.
/// 월간은 가로로 넘겨 달을 옮기고, 날짜 글자를 누르면 달력 팝업(앱을 쓰기 시작한 달부터)이 뜬다.
/// 주간 · 월간 그래프의 값은 재생 수 또는 재생 시간 (숫자 칸을 눌러 바꾼다).
class HistorySection extends StatefulWidget {
  const HistorySection({
    super.key,
    required this.summary,
    this.joinedAt,
    this.now,
  });

  final HomeSummary summary;

  /// 앱을 처음 쓴 날. 이 달 이전은 월간에서 볼 수 없다. 모르면 이번 달만.
  final DateTime? joinedAt;

  /// 기준 시각 (테스트용). 없으면 지금.
  final DateTime? now;

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  _View _view = _View.week;
  _Metric _metric = _Metric.plays;
  PageController? _pages;
  int _monthPage = 0;

  DateTime get _now => widget.now ?? DateTime.now();
  DateTime get _lastMonth => DateTime(_now.year, _now.month);
  DateTime get _firstMonth {
    final j = widget.joinedAt ?? _now;
    final first = DateTime(j.year, j.month);
    return first.isAfter(_lastMonth) ? _lastMonth : first;
  }

  int get _monthCount =>
      (_lastMonth.year - _firstMonth.year) * 12 +
      _lastMonth.month -
      _firstMonth.month +
      1;

  DateTime _monthAt(int page) =>
      DateTime(_firstMonth.year, _firstMonth.month + page);

  /// 처음에는 가장 최근(이번 달) 페이지에서 시작한다.
  PageController get _controller =>
      _pages ??= PageController(initialPage: _monthPage = _monthCount - 1);

  @override
  void didUpdateWidget(HistorySection old) {
    super.didUpdateWidget(old);
    // 가입일을 뒤늦게 읽어 페이지 수가 바뀌면 이번 달 페이지로 다시 맞춘다.
    if (old.joinedAt != widget.joinedAt) {
      _pages?.dispose();
      _pages = null;
    }
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
    page.clamp(0, _monthCount - 1),
    duration: AppMotion.medium,
    curve: AppMotion.standard,
  );

  Future<void> _pickMonth() async {
    final picked = await showMonthPickerDialog(
      context,
      selected: _monthAt(_monthPage.clamp(0, _monthCount - 1)),
      min: _firstMonth,
      max: _lastMonth,
    );
    if (picked == null) return;
    _goTo(
      (picked.year - _firstMonth.year) * 12 + picked.month - _firstMonth.month,
    );
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

    final Widget body;
    switch (_view) {
      case _View.week:
        final week = s.range(today.subtract(const Duration(days: 6)), today);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${week.first.day.month}/${week.first.day.day} ~ ${today.month}/${today.day}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            _Block(
              days: week,
              metric: _metric,
              onMetric: (m) => setState(() => _metric = m),
              weekly: true,
            ),
          ],
        );
      case _View.month:
        final shown = _monthAt(_monthPage.clamp(0, _monthCount - 1));
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ArrowButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: l10n.homeMonthPrev,
                  onTap: _monthPage <= 0 ? null : () => _goTo(_monthPage - 1),
                ),
                Expanded(
                  child: Center(
                    child: InkWell(
                      onTap: _pickMonth,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                              color: p.accent,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              l10n.homeMonthLabel(shown.year, shown.month),
                              style: text.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _ArrowButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: l10n.homeMonthNext,
                  onTap: _monthPage >= _monthCount - 1
                      ? null
                      : () => _goTo(_monthPage + 1),
                ),
              ],
            ),
            SizedBox(
              height: _Block.height,
              child: PageView.builder(
                controller: _controller,
                itemCount: _monthCount,
                onPageChanged: (i) => setState(() => _monthPage = i),
                itemBuilder: (context, i) {
                  final month = _monthAt(i);
                  final last = i == _monthCount - 1
                      ? today
                      : DateTime(month.year, month.month + 1, 0);
                  return _Block(
                    days: s.range(month, last),
                    metric: _metric,
                    onMetric: (m) => setState(() => _metric = m),
                    weekly: false,
                  );
                },
              ),
            ),
          ],
        );
      case _View.all:
        body = _AllStats(stats: s.stats);
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
        Padding(
          padding: AppSpacing.screen,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: body,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon),
      color: p.onSurface,
      disabledColor: p.onSurfaceMuted.withValues(alpha: .3),
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

  /// 월간 PageView 한 칸 높이.
  static const height = 250.0;

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

/// 전체: 재생 수 · 재생 시간 · 들은 날.
class _AllStats extends StatelessWidget {
  const _AllStats({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    Widget stat(String value, String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          StatNumber(value, size: 30),
        ],
      ),
    );

    return Column(
      children: [
        stat(l10n.playCount(stats.plays), l10n.homeAllPlays),
        stat(formatListened(l10n, stats.listened), l10n.homeAllTime),
        stat(l10n.homeAllDaysValue(stats.daysListened), l10n.homeAllDays),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 달력 팝업: 년 · 월을 고른다. [min]이 속한 달 이전(앱을 쓰기 전)과
/// [max]가 속한 달 이후는 고를 수 없다. 고르면 그 달의 1일, 닫으면 null.
Future<DateTime?> showMonthPickerDialog(
  BuildContext context, {
  required DateTime selected,
  required DateTime min,
  required DateTime max,
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => _MonthPicker(selected: selected, min: min, max: max),
);

class _MonthPicker extends StatefulWidget {
  const _MonthPicker({
    required this.selected,
    required this.min,
    required this.max,
  });

  final DateTime selected;
  final DateTime min;
  final DateTime max;

  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _year = widget.selected.year;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final first = DateTime(widget.min.year, widget.min.month);
    final last = DateTime(widget.max.year, widget.max.month);

    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.homePickMonth, style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: l10n.homeYearLabel(_year - 1),
                  onPressed: _year <= first.year
                      ? null
                      : () => setState(() => _year--),
                ),
                Text(l10n.homeYearLabel(_year), style: text.titleMedium),
                CircleIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: l10n.homeYearLabel(_year + 1),
                  onPressed: _year >= last.year
                      ? null
                      : () => setState(() => _year++),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 1.7,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: l10n.homeMonthShort(m),
                    selected:
                        _year == widget.selected.year &&
                        m == widget.selected.month,
                    enabled:
                        !DateTime(_year, m).isBefore(first) &&
                        !DateTime(_year, m).isAfter(last),
                    onTap: () => Navigator.of(context).pop(DateTime(_year, m)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme.labelLarge!;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? p.accent : p.surfaceHigh,
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: text.copyWith(
              color: selected
                  ? p.onAccent
                  : enabled
                  ? p.onSurface
                  : p.onSurfaceMuted.withValues(alpha: .4),
            ),
          ),
        ),
      ),
    );
  }
}

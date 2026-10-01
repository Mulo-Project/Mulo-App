import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 달 고르기 (달력): 해를 넘겨 가며 12개 달 중 하나를 누른다.
/// 오늘이 속한 달 이후는 고를 수 없다. 고르면 그 달의 1일, 닫으면 null.
Future<DateTime?> showMonthPickerSheet(
  BuildContext context, {
  required DateTime selected,
  required DateTime now,
}) => showModalBottomSheet<DateTime>(
  context: context,
  backgroundColor: context.palette.surface,
  showDragHandle: true,
  useRootNavigator: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
  ),
  builder: (_) => _MonthPicker(selected: selected, now: now),
);

class _MonthPicker extends StatefulWidget {
  const _MonthPicker({required this.selected, required this.now});

  final DateTime selected;
  final DateTime now;

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
    final now = widget.now;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: l10n.homeYearLabel(_year - 1),
                  onPressed: () => setState(() => _year--),
                ),
                Text(l10n.homeYearLabel(_year), style: text.titleMedium),
                CircleIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: l10n.homeYearLabel(_year + 1),
                  onPressed: _year >= now.year
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
                    enabled: DateTime(
                      _year,
                      m,
                    ).isBefore(DateTime(now.year, now.month + 1)),
                    onTap: () => Navigator.of(context).pop(DateTime(_year, m)),
                    accent: p.accent,
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
    required this.accent,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;

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
            color: selected ? accent : p.surfaceHigh,
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

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 여러 값 중 하나를 고르는 알약 묶음 (음질 · 포맷 · 탭 전환).
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    this.onChanged,
    this.expand = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T>? onChanged;

  /// true면 가로 폭을 똑같이 나눈다.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme.labelLarge!;

    Widget pill(T v) {
      final on = v == selected;
      return Semantics(
        selected: on,
        button: true,
        child: GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(v),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: ShapeDecoration(
              color: on ? p.accent : p.accent.withValues(alpha: 0),
              shape: const StadiumBorder(),
            ),
            child: Text(
              labelOf(v),
              style: text.copyWith(
                fontSize: 13,
                color: on ? p.onAccent : p.onSurfaceMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: onChanged == null ? .5 : 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: ShapeDecoration(
          color: p.surfaceHigh,
          shape: StadiumBorder(side: BorderSide(color: p.outline)),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (final v in values) expand ? Expanded(child: pill(v)) : pill(v),
          ],
        ),
      ),
    );
  }
}

/// 상태 표시용 작은 알약 (예: "받는 중", "연결 안 됨").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.emphasized = false});

  final String label;

  /// true면 강조 색 테두리 · 글자.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = emphasized ? p.accent : p.onSurfaceMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(color: color.withValues(alpha: .6)),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

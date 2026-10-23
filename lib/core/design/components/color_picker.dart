import '../icons/app_icons.dart';

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 커버 색 고르기: 자동 · 기본 색 견본 · 색상 막대로 직접 고르기.
///
/// 테마와 상관없이 고른 색 그대로 쓰므로 견본은 테마 토큰이 아니라 고정 색이다.
/// [selected]가 null이면 자동. 고르면 [onChanged]로 색, 자동을 누르면 null이 온다.
class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.autoLabel,
    required this.customLabel,
    this.optionLabel,
  });

  final Color? selected;
  final ValueChanged<Color?> onChanged;
  final String autoLabel;
  final String customLabel;

  /// 견본의 접근성 라벨 (예: "색 3"). 없으면 번호만.
  final String Function(int index)? optionLabel;

  /// 기본 견본 (색상 순). 흰 글자가 읽히는 중간 밝기.
  static const presets = <Color>[
    Color(0xFFE5484D),
    Color(0xFFF76B15),
    Color(0xFFF5A524),
    Color(0xFF3FA34D),
    Color(0xFF12A594),
    Color(0xFF0090C8),
    Color(0xFF3E63DD),
    Color(0xFF7C5CE0),
    Color(0xFFC13DB5),
    Color(0xFFE5467B),
    Color(0xFF8B6B4E),
    Color(0xFF5B6475),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final custom = selected != null && !presets.contains(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs - 2,
          runSpacing: AppSpacing.xs - 2,
          children: [
            _Dot(
              label: autoLabel,
              selected: selected == null,
              onTap: () => onChanged(null),
              child: Icon(
                AppIcons.refresh,
                size: AppSizes.iconSm,
                color: p.onSurface,
              ),
            ),
            for (final (i, c) in presets.indexed)
              _Dot(
                label: optionLabel?.call(i + 1) ?? '${i + 1}',
                color: c,
                selected: selected == c,
                onTap: () => onChanged(c),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          customLabel,
          style: text.labelMedium?.copyWith(
            color: custom ? p.accent : p.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        _HueBar(selected: custom ? selected : null, onChanged: onChanged),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.child,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: AppMotion.medium,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadii.sm - 4),
                border: Border.all(
                  color: selected ? p.accent : p.outline,
                  width: selected ? 2 : 1,
                ),
              ),
              child:
                  child ??
                  (selected
                      ? Icon(
                          AppIcons.check,
                          size: AppSizes.iconSm,
                          color: p.onGlow,
                        )
                      : null),
            ),
          ),
        ),
      ),
    );
  }
}

/// 색상(hue) 막대. 끌거나 눌러서 색을 고른다 (채도 · 명도는 고정).
class _HueBar extends StatelessWidget {
  const _HueBar({required this.selected, required this.onChanged});

  final Color? selected;
  final ValueChanged<Color?> onChanged;

  static const _saturation = .7;
  static const _lightness = .48;
  static const _height = 20.0;

  static final _hues = [
    for (var h = 0; h <= 360; h += 30)
      HSLColor.fromAHSL(
        1,
        h.toDouble() % 360,
        _saturation,
        _lightness,
      ).toColor(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hue = selected == null ? null : HSLColor.fromColor(selected!).hue;

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        void pick(double dx) {
          final h = (dx / width).clamp(0.0, 1.0) * 360;
          onChanged(
            HSLColor.fromAHSL(
              1,
              h >= 360 ? 359.9 : h,
              _saturation,
              _lightness,
            ).toColor(),
          );
        }

        return Semantics(
          slider: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition.dx),
            onHorizontalDragStart: (d) => pick(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
            child: SizedBox(
              height: _height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        gradient: LinearGradient(colors: _hues),
                      ),
                    ),
                  ),
                  if (hue != null)
                    Positioned(
                      left: (hue / 360 * width - 3).clamp(0, width - 6),
                      top: -2,
                      bottom: -2,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: p.onGlow,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: p.outline),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

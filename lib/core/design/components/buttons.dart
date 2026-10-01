import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'glass.dart';

enum PillVariant {
  /// 강조 색(라임) 채움 + 은은한 빛 — 화면의 주 동작.
  accent,

  /// 주 색(바이올렛) 채움.
  primary,

  /// 무색 유리.
  tonal,

  /// 테두리만 (유리 테두리, 채움 없음).
  outline,
}

/// 알약 모양 버튼.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = PillVariant.accent,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PillVariant variant;

  /// 토글 · 필터로 쓸 때 선택 상태. true면 accent 모양으로 그린다.
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = selected ? PillVariant.accent : variant;
    final fg = switch (v) {
      PillVariant.accent => p.onAccent,
      PillVariant.primary => p.onPrimary,
      PillVariant.tonal || PillVariant.outline => p.onSurface,
    };
    final enabled = onPressed != null;
    final text = Theme.of(context).textTheme.labelLarge!.copyWith(color: fg);
    final height = compact ? 36.0 : AppSizes.pillHeight;

    final content = SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.md : AppSpacing.lg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    final Widget button = switch (v) {
      PillVariant.tonal => GlassSurface(
        shape: const StadiumBorder(),
        onTap: onPressed,
        child: content,
      ),
      PillVariant.outline => GlassSurface(
        shape: const StadiumBorder(),
        onTap: onPressed,
        blur: 0,
        child: content,
      ),
      PillVariant.accent || PillVariant.primary => _SolidPill(
        color: v == PillVariant.accent ? p.accent : p.primary,
        onTap: onPressed,
        child: content,
      ),
    };

    return Opacity(opacity: enabled ? 1 : .4, child: button);
  }
}

class _SolidPill extends StatelessWidget {
  const _SolidPill({required this.color, required this.child, this.onTap});

  final Color color;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.medium,
    curve: AppMotion.standard,
    decoration: ShapeDecoration(
      color: color,
      shape: const StadiumBorder(),
      shadows: [
        BoxShadow(
          color: color.withValues(alpha: .35),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: child,
      ),
    ),
  );
}

/// 원형 아이콘 버튼. 기본은 무색 유리, [emphasized]면 강조 색 + 빛 (재생 버튼 등).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.emphasized = false,
    this.size = AppSizes.circleButton,
    this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool emphasized;
  final double size;

  /// 길게 누르기. 주면 길게 눌러 툴팁을 띄우지 않는다 (마우스를 올리면 그대로 뜬다).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final glyph = SizedBox.square(
      dimension: size,
      child: Icon(
        icon,
        size: size * .48,
        color: emphasized ? p.onAccent : p.onSurface,
      ),
    );

    final button = emphasized
        ? DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: p.accent.withValues(alpha: .45),
                  blurRadius: size * .45,
                ),
              ],
            ),
            child: Material(
              color: p.accent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onPressed, child: glyph),
            ),
          )
        : GlassSurface(
            shape: const CircleBorder(),
            onTap: onPressed,
            child: glyph,
          );

    return Tooltip(
      message: tooltip,
      triggerMode: onLongPress == null ? null : TooltipTriggerMode.manual,
      child: onLongPress == null
          ? button
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: onLongPress,
              child: button,
            ),
    );
  }
}

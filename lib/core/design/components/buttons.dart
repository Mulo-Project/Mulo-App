import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

enum PillVariant {
  /// 강조 색(라임) 채움 — 화면의 주 동작.
  accent,

  /// 주 색(바이올렛) 채움.
  primary,

  /// 한 단계 뜬 어두운 면.
  tonal,

  /// 테두리만.
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
    final (bg, fg, border) = switch (v) {
      PillVariant.accent => (p.accent, p.onAccent, null),
      PillVariant.primary => (p.primary, p.onPrimary, null),
      PillVariant.tonal => (p.surfaceHigh, p.onSurface, null),
      PillVariant.outline => (Colors.transparent, p.onSurface, p.outline),
    };
    final enabled = onPressed != null;
    final text = Theme.of(context).textTheme.labelLarge!.copyWith(color: fg);

    return Opacity(
      opacity: enabled ? 1 : .4,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        height: compact ? 36 : AppSizes.pillHeight,
        decoration: ShapeDecoration(
          color: bg,
          shape: StadiumBorder(
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.md : AppSpacing.lg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
          ),
        ),
      ),
    );
  }
}

/// 어두운 원형 아이콘 버튼. [emphasized]면 강조 색으로 채운다 (재생 버튼 등).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.emphasized = false,
    this.size = AppSizes.circleButton,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool emphasized;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = emphasized ? p.accent : p.surfaceHigh;
    final fg = emphasized ? p.onAccent : p.onSurface;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: size * .48, color: fg),
          ),
        ),
      ),
    );
  }
}

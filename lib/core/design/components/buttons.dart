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
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PillVariant variant;

  /// 토글 · 필터로 쓸 때 선택 상태. true면 accent 모양으로 그린다.
  final bool selected;
  final bool compact;

  /// 일하는 중: 아이콘 자리에 돌아가는 표시를 보인다 (누를 수는 있다).
  final bool busy;

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
            if (busy) ...[
              _Spinner(size: 16, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ] else if (icon != null) ...[
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

/// 작게 돌아가는 진행 표시 (버튼 안에서 "불러오는 중"을 보일 때).
class _Spinner extends StatelessWidget {
  const _Spinner({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}

/// 목록 줄 오른쪽에 놓는 작은 아이콘 버튼. 유리 면 · 흐림 없이 아이콘만 있고 눌림 효과만 있다
/// (줄마다 놓여도 스크롤이 가볍다). [accent]면 강조 색, [active]면 켜진 상태(예: 미리 듣는 중).
class RowIconButton extends StatelessWidget {
  const RowIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.accent = false,
    this.busy = false,
    this.busyChild,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// 강조 색으로 그린다 (켜진 상태 · 주 동작).
  final bool accent;

  /// 일하는 중: 아이콘 대신 돌아가는 표시를 보인다 (누를 수는 있다).
  final bool busy;

  /// [busy]일 때 돌아가는 표시 대신 둘 위젯 (예: 남은 시간 원). 없으면 기본 표시.
  final Widget? busyChild;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: AppSizes.rowButton,
            child: busy
                ? Center(
                    child: busyChild ?? _Spinner(size: 18, color: p.accent),
                  )
                : Icon(
                    icon,
                    size: AppSizes.rowButton * .56,
                    color: accent ? p.accent : p.onSurface,
                  ),
          ),
        ),
      ),
    );
  }
}

/// 작고 단순한 글자 · 아이콘 버튼. 면 · 테두리 없이 눌림 효과만 있다 (보조 동작, 한 줄에 여러 개).
class PlainButton extends StatelessWidget {
  const PlainButton({
    super.key,
    this.label,
    this.icon,
    this.tooltip,
    this.onPressed,
    this.accent = false,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  /// 강조 색으로 그린다 (저장 같은 주 동작).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = accent ? p.accent : p.onSurface;
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(color: fg);
    final button = Opacity(
      opacity: onPressed == null ? .4 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) Icon(icon, size: 16, color: fg),
                if (icon != null && label != null)
                  const SizedBox(width: AppSpacing.xxs),
                if (label != null) Flexible(child: Text(label!, style: style)),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

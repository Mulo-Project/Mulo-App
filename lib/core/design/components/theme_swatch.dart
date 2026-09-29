import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import '../tokens/app_palette.dart';
import 'glass.dart';

/// 테마 색 고르기 동그라미. [preview] 팔레트의 유리 색과 강조 색을 미리 보여 준다.
///
/// 이 위젯만 "다른 팔레트"를 그리므로 현재 테마 토큰이 아니라 [preview]에서 색을 읽는다.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    super.key,
    required this.preview,
    required this.label,
    required this.selected,
    this.onTap,
    this.size = 52,
  });

  final AppPalette preview;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: ExcludeSemantics(
          child: SizedBox(
            width: size + AppSpacing.md,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.standard,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? p.onSurface : p.glassBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: GlassSurface(
                    shape: const CircleBorder(),
                    tint: preview.glowPrimary,
                    blur: 0,
                    child: SizedBox.square(
                      dimension: size - 8,
                      child: Center(
                        child: AnimatedContainer(
                          duration: AppMotion.medium,
                          width: selected ? 20 : 12,
                          height: selected ? 20 : 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: preview.accent,
                            boxShadow: [
                              BoxShadow(
                                color: preview.accent.withValues(alpha: .6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: preview.onAccent,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: selected ? p.onSurface : p.onSurfaceMuted,
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

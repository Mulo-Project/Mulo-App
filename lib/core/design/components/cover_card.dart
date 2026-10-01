import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 이미지 카드 (재생목록 · 플레이어 커버). 유리 효과 없이 이미지를 그대로 보여 준다.
///
/// 이미지가 없으면 [tone] 그라데이션. [child]는 위에 겹쳐 그리며,
/// [shade]가 true면 글자가 읽히도록 아래쪽을 어둡게 한다.
/// 사진 · 그라데이션 위 글자는 테마와 관계없이 흰색 계열([AppPalette.onGlow]).
class CoverCard extends StatelessWidget {
  const CoverCard({
    super.key,
    this.image,
    this.tone = GlowTone.primary,
    this.radius = AppRadii.card,
    this.shade = false,
    this.onTap,
    this.onLongPress,
    this.child,
  });

  final ImageProvider? image;
  final GlowTone tone;
  final double radius;
  final bool shade;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final glow = context.tokens.glow(tone);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return Material(
      shape: shape,
      clipBehavior: Clip.antiAlias,
      color: glow[1],
      child: Ink(
        decoration: image != null
            ? BoxDecoration(
                image: DecorationImage(image: image!, fit: BoxFit.cover),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: glow,
                ),
              ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: shade
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        p.scrim.withValues(alpha: 0),
                        p.scrim.withValues(alpha: .65),
                      ],
                    )
                  : null,
            ),
            child: onGlow(context, child ?? const SizedBox.expand()),
          ),
        ),
      ),
    );
  }
}

/// 색 · 사진 위에 그리는 내용의 글자 · 아이콘 색을 [AppPalette.onGlow]로 바꾼다.
Widget onGlow(BuildContext context, Widget child) {
  final theme = Theme.of(context);
  final p = context.palette;
  final on = p.onGlow;
  return Theme(
    data: theme.copyWith(
      textTheme: theme.textTheme.apply(bodyColor: on, displayColor: on),
      iconTheme: theme.iconTheme.copyWith(color: on),
      extensions: [
        AppThemeTokens(
          palette: p.copyWith(
            onSurface: on,
            onSurfaceMuted: on.withValues(alpha: .75),
          ),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: on),
      child: child,
    ),
  );
}

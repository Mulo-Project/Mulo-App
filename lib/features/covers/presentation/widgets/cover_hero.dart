import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// 상세 정보 화면 맨 위의 큰 커버. 누르면 [onTap](이미지 편집)이 열리고,
/// 눌러서 바꿀 수 있다는 것을 오른쪽 아래의 작은 연필로 알려 준다.
class CoverHero extends StatelessWidget {
  const CoverHero({
    super.key,
    required this.image,
    required this.onTap,
    this.color,
    this.tone = GlowTone.neutral,
    this.icon = AppIcons.musicNote,
    this.size = 220,
    this.circle = false,
  });

  final ImageProvider? image;
  final Color? color;
  final GlowTone tone;
  final IconData icon;
  final double size;

  /// 아티스트처럼 동그란 커버.
  final bool circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              ArtworkBox(
                image: image,
                size: size,
                radius: circle ? size / 2 : AppRadii.md,
                tone: tone,
                color: color,
                icon: icon,
              ),
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: p.background.withValues(alpha: .7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(AppIcons.edit, size: 16, color: p.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

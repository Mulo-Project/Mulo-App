import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 이미지를 정하는 줄: 지금 이미지(없으면 기본 커버) · 이름 · "이미지 고르기 / 바꾸기".
/// 곡 · 앨범 · 재생목록 · 받기 어디서든 이 한 줄이 같은 이미지 페이지([showCoverEditor])를 연다
/// (이미지를 고르는 일도, 위치를 맞추는 일도, 기본으로 되돌리는 일도 그 페이지 하나가 맡는다).
class CoverEntry extends StatelessWidget {
  const CoverEntry({
    super.key,
    required this.image,
    required this.label,
    required this.onTap,
    this.tone = GlowTone.neutral,
    this.color,
    this.icon = AppIcons.musicNote,
  });

  final ImageProvider? image;
  final String label;
  final VoidCallback onTap;
  final GlowTone tone;
  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ArtworkBox(
            image: image,
            size: 72,
            radius: AppRadii.sm,
            tone: tone,
            color: color,
            icon: icon,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              PillButton(
                label: image == null ? l10n.coverPick : l10n.coverChange,
                icon: AppIcons.photoLibrary,
                compact: true,
                variant: PillVariant.tonal,
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

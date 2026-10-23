import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'cover_entry.dart';

/// 꾸미기 시트들이 같이 쓰는 설정 구역: 이미지 줄([CoverEntry]) + (이미지 없을 때 쓰이는) 색 고르기.
/// 곡 · 앨범 · 아티스트 · 재생목록 꾸미기와 새 재생목록 만들기가 모두 이 한 구역을 쓴다.
class CoverSettingsSection extends StatelessWidget {
  const CoverSettingsSection({
    super.key,
    required this.image,
    required this.color,
    required this.onEditImage,
    required this.onColorChanged,
    this.tone = GlowTone.neutral,
    this.icon = AppIcons.musicNote,
    this.showColor = true,
  });

  final ImageProvider? image;

  /// 고른 색 (null이면 자동).
  final Color? color;
  final VoidCallback onEditImage;

  /// 색을 고르면 색, 자동을 누르면 null.
  final ValueChanged<Color?> onColorChanged;
  final GlowTone tone;
  final IconData icon;

  /// false면 색 고르기를 숨긴다 (좋아요 목록 · 이미지가 있어 색이 보이지 않을 때).
  final bool showColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoverEntry(
          image: image,
          label: l10n.decorateImage,
          tone: tone,
          color: color,
          icon: icon,
          onTap: onEditImage,
        ),
        if (showColor) ...[
          const SizedBox(height: AppSpacing.md),
          const AppDivider(),
          const SizedBox(height: AppSpacing.md),
          SectionTitle(l10n.decorateColor, padded: false),
          const SizedBox(height: AppSpacing.xs),
          ColorPicker(
            selected: color,
            autoLabel: l10n.playlistColorAuto,
            customLabel: l10n.colorCustom,
            optionLabel: l10n.colorOption,
            onChanged: onColorChanged,
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'artwork_box.dart';

/// 곡 한 줄: 커버 · 제목 · 부제 · 오른쪽 위젯.
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.tone = GlowTone.primary,
    this.artwork,
    this.leading,
    this.trailing,
    this.footer,
    this.active = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final GlowTone tone;
  final ImageProvider? artwork;

  /// 커버 대신 둘 위젯 (예: 선택 체크).
  final Widget? leading;
  final Widget? trailing;

  /// 제목 아래 추가 줄 (예: 다운로드 진행 막대).
  final Widget? footer;

  /// 지금 재생 중인 곡이면 제목을 강조 색으로.
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            leading ?? ArtworkBox(image: artwork, tone: tone),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      color: active ? p.accent : p.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    footer!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

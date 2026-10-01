import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 설정 › 테마 미리보기 화면의 내용. 지금 적용된 팔레트(색 · 화면 모드)로
/// 미니 플레이어 · 곡 줄 · 버튼 · 카드 샘플을 그려, 고르는 즉시 모습을 보여 준다.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  tone: GlowTone.secondary,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.navLibrary, style: text.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      const StatNumber('128', size: 32),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GlassCard(
                  tone: GlowTone.tertiary,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.navPlaylists, style: text.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      const StatNumber('12', size: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TrackTile(
            title: l10n.themePreviewSong,
            subtitle: l10n.themePreviewArtist,
            active: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              PillButton(
                label: l10n.actionPlayAll,
                icon: Icons.play_arrow_rounded,
                compact: true,
                onPressed: () {},
              ),
              PillButton(
                label: l10n.actionShuffle,
                icon: Icons.shuffle_rounded,
                compact: true,
                variant: PillVariant.tonal,
                onPressed: () {},
              ),
              PillButton(
                label: l10n.actionCancel,
                compact: true,
                variant: PillVariant.outline,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          MiniPlayerBar(
            title: l10n.themePreviewSong,
            artist: l10n.themePreviewArtist,
            progress: .62,
            isPlaying: true,
            playLabel: l10n.actionPlay,
            pauseLabel: l10n.actionPause,
            nextLabel: l10n.actionNext,
          ),
        ],
      ),
    );
  }
}

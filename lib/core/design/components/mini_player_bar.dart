import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'buttons.dart';
import 'dotted_progress.dart';

/// 하단 미니 플레이어 골격. 재생 상태는 아직 없으므로 값을 밖에서 받는다.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.title,
    required this.artist,
    required this.progress,
    required this.isPlaying,
    this.artwork,
    this.onTap,
    this.onPlayPause,
    this.onNext,
  });

  final String title;
  final String artist;
  final double progress;
  final bool isPlaying;

  /// 커버 아트. 없으면 주 색 그라데이션 자리 표시.
  final ImageProvider? artwork;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: p.outline.withValues(alpha: .4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _Artwork(artwork: artwork),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          artist,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    tooltip: isPlaying ? '일시정지' : '재생',
                    emphasized: true,
                    onPressed: onPlayPause,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CircleIconButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: '다음 곡',
                    onPressed: onNext,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DottedProgressBar(value: progress, height: 3, spacing: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({this.artwork});

  final ImageProvider? artwork;

  @override
  Widget build(BuildContext context) {
    final glow = context.tokens.glow(GlowTone.primary);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: SizedBox.square(
        dimension: 44,
        child: artwork != null
            ? Image(image: artwork!, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: glow,
                  ),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: context.palette.onSurface,
                  size: 20,
                ),
              ),
      ),
    );
  }
}

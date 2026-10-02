import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'buttons.dart';
import 'glass.dart';
import 'progress.dart';

/// 하단 미니 플레이어 (유리 면). 가로 전체를 쓰고 모서리는 둥글리지 않는다.
/// 재생 상태는 밖에서 받는다.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.title,
    required this.artist,
    required this.progress,
    required this.isPlaying,
    required this.playLabel,
    required this.pauseLabel,
    required this.nextLabel,
    required this.queueLabel,
    this.artwork,
    this.onTap,
    this.onPlayPause,
    this.onNext,
    this.onQueue,
  });

  final String title;
  final String artist;
  final double progress;
  final bool isPlaying;

  /// 버튼 설명 (다국어 문구를 밖에서 받는다).
  final String playLabel;
  final String pauseLabel;
  final String nextLabel;
  final String queueLabel;

  /// 커버 아트. 없으면 주 색 그라데이션 자리 표시.
  final ImageProvider? artwork;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  /// 재생 대기열을 바로 연다.
  final VoidCallback? onQueue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    // 가로 전체 띠라서 좌우 세로 선은 없애고 위쪽 가는 선만 긋는다.
    return GlassSurface(
      shape: const RoundedRectangleBorder(),
      rim: false,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.glassBorder)),
        ),
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
                    tooltip: isPlaying ? pauseLabel : playLabel,
                    emphasized: true,
                    onPressed: onPlayPause,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CircleIconButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: nextLabel,
                    onPressed: onNext,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CircleIconButton(
                    icon: Icons.queue_music_rounded,
                    tooltip: queueLabel,
                    onPressed: onQueue,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ProgressLine(value: progress, height: 3),
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
                  color: context.palette.onGlow,
                  size: 20,
                ),
              ),
      ),
    );
  }
}

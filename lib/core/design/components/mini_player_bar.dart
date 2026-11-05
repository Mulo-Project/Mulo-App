import '../icons/app_icons.dart';

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'buttons.dart';
import 'marquee_text.dart';
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
    required this.previousLabel,
    required this.nextLabel,
    required this.positionText,
    required this.durationText,
    required this.queueLabel,
    this.artwork,
    this.video,
    this.onTap,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onQueue,
    this.showSkip = true,
    this.queueIcon = AppIcons.queue,
  });

  final String title;
  final String artist;
  final double progress;
  final bool isPlaying;

  /// 현재 재생 시간 · 곡 길이 ("1:23" 형태, 밖에서 만들어 받는다).
  final String positionText;
  final String durationText;

  /// 버튼 설명 (다국어 문구를 밖에서 받는다).
  final String playLabel;
  final String pauseLabel;
  final String previousLabel;
  final String nextLabel;
  final String queueLabel;

  /// 커버 아트. 없으면 주 색 그라데이션 자리 표시.
  final ImageProvider? artwork;

  /// 영상 곡이면 커버 대신 보여 줄 영상 화면 (소리 없는 화면, 안 열리는 동안은 커버가 보인다).
  final Widget? video;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// 재생 대기열을 바로 연다.
  final VoidCallback? onQueue;

  /// 이전 · 다음 버튼을 보일지 (미리 듣기처럼 넘길 곡이 없을 땐 숨긴다).
  final bool showSkip;

  /// 맨 오른쪽 작은 아이콘 ([queueLabel]이 그 설명). 기본은 재생목록.
  final IconData queueIcon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    // 가로 전체 띠라서 좌우 세로 선은 없애고 위쪽 가는 선만 긋는다.
    return GlassSurface(
      shape: const RoundedRectangleBorder(),
      rim: false,
      solid: true,
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
                  _Artwork(artwork: artwork, video: video),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarqueeText(title, style: text.titleSmall),
                        Text(
                          artist,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 제목 영역(누르면 상세/플레이어)과 조작 버튼 영역을 가는 선으로 가른다.
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    height: 32,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: p.glassBorder,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (showSkip)
                    _BarIcon(
                      icon: AppIcons.skipPrevious,
                      tooltip: previousLabel,
                      onPressed: onPrevious,
                    ),
                  CircleIconButton(
                    icon: isPlaying ? AppIcons.pause : AppIcons.play,
                    tooltip: isPlaying ? pauseLabel : playLabel,
                    emphasized: true,
                    onPressed: onPlayPause,
                  ),
                  if (showSkip)
                    _BarIcon(
                      icon: AppIcons.skipNext,
                      tooltip: nextLabel,
                      onPressed: onNext,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // 재생 시간 · 진행선 · 곡 길이, 맨 오른쪽에 작은 재생목록 아이콘.
              Row(
                children: [
                  _TimeText(positionText),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: ProgressLine(value: progress, height: 3)),
                  const SizedBox(width: AppSpacing.xs),
                  _TimeText(durationText),
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: queueLabel,
                    child: InkResponse(
                      onTap: onQueue,
                      radius: 14,
                      child: Icon(
                        queueIcon,
                        size: AppSizes.iconXs,
                        color: p.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({this.artwork, this.video});

  final ImageProvider? artwork;
  final Widget? video;

  @override
  Widget build(BuildContext context) {
    final glow = context.tokens.glow(GlowTone.primary);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: SizedBox(
        // 영상은 가로로 넓게(16:9) 보여 준다.
        width: video != null ? 78 : 44,
        height: 44,
        child: video != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (artwork != null) Image(image: artwork!, fit: BoxFit.cover),
                  video!,
                ],
              )
            : artwork != null
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
                  AppIcons.musicNote,
                  color: context.palette.onGlow,
                  size: AppSizes.iconMd,
                ),
              ),
      ),
    );
  }
}

/// 작은 아이콘 버튼 (배경 없음).
class _BarIcon extends StatelessWidget {
  const _BarIcon({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            icon,
            size: AppSizes.icon,
            color: context.palette.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

/// 아주 작은 시간 글자.
class _TimeText extends StatelessWidget {
  const _TimeText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.palette.onSurfaceMuted,
        fontSize: 10,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

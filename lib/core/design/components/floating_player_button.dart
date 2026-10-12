import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../icons/app_icons.dart';
import '../tokens/app_dimens.dart';
import 'glass.dart';
import 'progress.dart';

/// 미니 플레이어를 끌어내 만든 동그란 플로팅 버튼. 커버 아트 위로 재생 진행이 테두리로 차오른다.
/// 가운데를 누르면 재생 · 일시정지([onPlayPause]), 모서리의 작은 점을 누르면 미니 플레이어로 돌아간다([onExpand]).
/// 위치는 밖에서 정한다 (끌어 옮기는 제스처도 밖에서 감싼다).
class FloatingPlayerButton extends StatelessWidget {
  const FloatingPlayerButton({
    super.key,
    required this.progress,
    required this.isPlaying,
    required this.playLabel,
    required this.pauseLabel,
    required this.expandLabel,
    this.artwork,
    this.onPlayPause,
    this.onExpand,
    this.bubbleSide = const Offset(1, -1),
  });

  static const size = 60.0;
  static const _badge = 26.0;
  static const _badgePad = 9.0;

  /// 돌아가기 점이 버튼 둘레 어느 쪽으로 뻗어 나가도 들어가도록 버튼 둘레에 둔 여백.
  static const reach = 27.0;

  /// 버튼 + 둘레 여백 전체 크기. 위치는 둥근 버튼의 왼쪽 위 기준으로 잡고, 이 틀은 그만큼 바깥으로 나온다.
  static const boxSize = size + reach * 2;

  /// 버튼 중심에서 점 중심까지 한 축당 거리 (비스듬히 뻗은 거품처럼).
  static const _bubbleOffset = 35.0;

  final double progress;
  final bool isPlaying;
  final String playLabel;
  final String pauseLabel;
  final String expandLabel;
  final ImageProvider? artwork;
  final VoidCallback? onPlayPause;
  final VoidCallback? onExpand;

  /// 돌아가기 점이 뻗은 쪽: 각 축 -1 또는 1 (예: (1, -1) = 오른쪽 위). 바뀌면 부드럽게 옮겨 간다.
  final Offset bubbleSide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final glow = context.tokens.glow(GlowTone.primary);
    const ring = 3.0;

    const half = boxSize / 2;
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: reach,
            top: reach,
            width: size,
            height: size,
            child: Tooltip(
              message: isPlaying ? pauseLabel : playLabel,
              child: GlassSurface(
                shape: CircleBorder(
                  side: BorderSide(color: p.accent.withValues(alpha: .4)),
                ),
                glow: true,
                onTap: onPlayPause,
                child: Center(
                  child: CountdownRing(
                    value: progress,
                    size: size - 6,
                    stroke: ring,
                    child: ClipOval(
                      child: SizedBox.square(
                        dimension: size - 6 - ring * 2 - 4,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (artwork != null)
                              Image(image: artwork!, fit: BoxFit.cover)
                            else
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: glow,
                                  ),
                                ),
                              ),
                            ColoredBox(
                              color: p.scrim.withValues(alpha: .5),
                              child: Icon(
                                isPlaying ? AppIcons.pause : AppIcons.play,
                                size: 22,
                                color: p.onGlow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            // 점 하나의 누르는 범위는 44. 중심이 (half ± offset)에 오도록 둔다.
            left: half + bubbleSide.dx * _bubbleOffset - _badge / 2 - _badgePad,
            top: half + bubbleSide.dy * _bubbleOffset - _badge / 2 - _badgePad,
            duration: AppMotion.medium,
            curve: Curves.easeOutBack,
            child: Tooltip(
              message: expandLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onExpand,
                // 작은 점이라 눌리는 범위만 넓힌다.
                child: Padding(
                  padding: const EdgeInsets.all(_badgePad),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent,
                      border: Border.all(color: p.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: p.accent.withValues(alpha: .55),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: SizedBox.square(
                      dimension: _badge,
                      child: Icon(
                        AppIcons.dockDown,
                        size: 20,
                        color: p.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

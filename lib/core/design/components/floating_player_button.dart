import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../icons/app_icons.dart';
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
  });

  static const size = 60.0;
  static const _badge = 26.0;
  static const _badgePad = 9.0;

  /// 전체 높이: 위의 돌아가기 점(누르는 범위 포함) + 둥근 버튼. 점은 버튼에서 떨어져 있어 누르기 편하다.
  static const height = size + _badge + _badgePad * 2;

  final double progress;
  final bool isPlaying;
  final String playLabel;
  final String pauseLabel;
  final String expandLabel;
  final ImageProvider? artwork;
  final VoidCallback? onPlayPause;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final glow = context.tokens.glow(GlowTone.primary);
    const ring = 3.0;

    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
          Positioned(
            top: 0,
            left: (size - _badge - _badgePad * 2) / 2,
            child: Tooltip(
              message: expandLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onExpand,
                // 작은 점이라 눌리는 범위만 넓힌다 (버튼과는 떨어져 있다).
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
                        AppIcons.expandLess,
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

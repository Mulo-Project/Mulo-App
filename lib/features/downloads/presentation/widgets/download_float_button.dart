import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/download_queue_cubit.dart';

/// 받기 줄을 접어 둔 동그란 플로팅 버튼. 전체 진행도가 테두리로 차오른다.
/// 하단 바 바로 위 오른쪽에 고정돼 있고, 누르면 [onRestore]로 받기 줄이 다시 펴진다.
/// 받는 곡이 없으면 아무것도 그리지 않는다.
/// 본문 위에 얹는 용도라서 부모 [Stack]이 본문 전체 크기여야 한다.
class DownloadFloatButton extends StatelessWidget {
  const DownloadFloatButton({super.key, required this.onRestore});

  static const size = 56.0;

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<DownloadQueueCubit>().state;
    if (queue.current == null) return const SizedBox.shrink();
    final p = context.palette;
    final l10n = context.l10n;
    // 본문은 하단 바 뒤로 이어지므로, 아래 여백이 곧 하단 바 높이다.
    final barHeight = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Positioned(
          right: AppSpacing.md,
          bottom: barHeight + AppSpacing.md,
          // 띠가 다 접힌 뒤 제자리에서 커지며 나타난다.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.medium,
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(
              scale: t,
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            ),
            child: GestureDetector(
              key: const ValueKey('download-float'),
              onTap: onRestore,
              child: Tooltip(
                message: l10n.downloadsExpand,
                child: GlassSurface(
                  shape: CircleBorder(
                    side: BorderSide(color: p.accent.withValues(alpha: .4)),
                  ),
                  child: SizedBox.square(
                    dimension: size,
                    child: Center(
                      child: CountdownRing(
                        value: queue.overallProgress,
                        size: size - 12,
                        child: Icon(
                          AppIcons.download,
                          size: 20,
                          color: p.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

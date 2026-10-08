import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/download_queue_cubit.dart';

/// 받기 줄을 접어 둔 동그란 플로팅 버튼. 전체 진행도가 테두리로 차오른다.
/// 손가락으로 아무 데나 끌어 둘 수 있고, 화면 아래쪽(하단 바 자리)에 가져다 놓거나 누르면
/// [onRestore]로 받기 줄이 다시 켜진다. 받는 곡이 없으면 아무것도 그리지 않는다.
/// 본문 위에 얹는 용도라서 부모 [Stack]이 본문 전체 크기여야 한다.
class DownloadFloatButton extends StatefulWidget {
  const DownloadFloatButton({
    super.key,
    required this.position,
    required this.onMoved,
    required this.onRestore,
  });

  static const size = 56.0;

  /// 왼쪽 위 좌표. null이면 오른쪽 아래 기본 자리.
  final Offset? position;
  final ValueChanged<Offset> onMoved;
  final VoidCallback onRestore;

  @override
  State<DownloadFloatButton> createState() => _DownloadFloatButtonState();
}

class _DownloadFloatButtonState extends State<DownloadFloatButton> {
  /// 끌고 있는 동안의 가장 최근 자리 (놓을 때 판단하려고, 다시 그리기를 기다리지 않는다).
  Offset? _latest;

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    const size = DownloadFloatButton.size;
    final queue = context.watch<DownloadQueueCubit>().state;
    if (queue.current == null) return const SizedBox.shrink();
    final p = context.palette;
    final l10n = context.l10n;
    // 본문은 하단 바 뒤로 이어지므로, 아래 여백이 곧 하단 바 높이다.
    final barHeight = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, box) {
        final maxX = box.maxWidth - size;
        final maxY = box.maxHeight - size;
        final home = Offset(
          maxX - AppSpacing.md,
          maxY - barHeight - AppSpacing.md,
        );
        final at = widget.position ?? home;
        final pos = Offset(at.dx.clamp(0.0, maxX), at.dy.clamp(0.0, maxY));
        // 하단 바 자리에 걸치면 놓을 때 받기 줄로 돌아간다.
        bool inDock(Offset o) => o.dy + size / 2 >= box.maxHeight - barHeight;
        final docking = inDock(pos);

        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                key: const ValueKey('download-float'),
                onTap: widget.onRestore,
                onPanStart: (_) => _latest = pos,
                onPanUpdate: (d) {
                  final from = _latest ?? pos;
                  final next = Offset(
                    (from.dx + d.delta.dx).clamp(0.0, maxX),
                    (from.dy + d.delta.dy).clamp(0.0, maxY),
                  );
                  _latest = next;
                  widget.onMoved(next);
                },
                onPanEnd: (_) {
                  final end = _latest ?? pos;
                  _latest = null;
                  if (inDock(end)) widget.onRestore();
                },
                child: Tooltip(
                  message: l10n.downloadsExpand,
                  child: GlassSurface(
                    shape: CircleBorder(
                      side: BorderSide(
                        color: p.accent.withValues(alpha: docking ? .9 : .4),
                      ),
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
          ],
        );
      },
    );
  }
}

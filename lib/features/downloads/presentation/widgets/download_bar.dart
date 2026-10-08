import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/download_queue_cubit.dart';
import 'download_item_widgets.dart';

/// 모든 탭 아래쪽(미니 플레이어 위)에 붙는 얇은 받기 진행 줄.
/// 한 줄에 지금 받는 곡 제목 · 진행 막대 · 남은 곡 수 · 펼치기 · 전체 취소가 있고,
/// 누르면 아래로 펼쳐져 아직 끝나지 않은 곡 목록이 보인다. 받는 곡이 없으면 아무것도 그리지 않는다.
/// 유리는 이 띠 하나에만 쓰고, 펼친 목록의 줄에는 쓰지 않는다.
class DownloadBar extends StatefulWidget {
  const DownloadBar({super.key});

  @override
  State<DownloadBar> createState() => _DownloadBarState();
}

class _DownloadBarState extends State<DownloadBar> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<DownloadQueueCubit>().state;
    final current = queue.current;
    if (current == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final pending = [
      for (final i in queue.items)
        if (i.status != DownloadStatus.done) i,
    ];

    return GlassSurface(
      key: const ValueKey('download-bar'),
      shape: const RoundedRectangleBorder(),
      rim: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              key: const ValueKey('download-bar-toggle'),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.download, size: 16, color: p.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      flex: 3,
                      child: Text(
                        current.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: ProgressLine(
                        value: queue.overallProgress,
                        height: 3,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${(current.progress * 100).round()}% · '
                      '${l10n.downloadsRemaining(pending.length)}',
                      style: text.labelSmall?.copyWith(color: p.onSurfaceMuted),
                    ),
                    Tooltip(
                      message: _expanded
                          ? l10n.downloadsCollapse
                          : l10n.downloadsExpand,
                      child: Icon(
                        _expanded ? AppIcons.expandMore : AppIcons.expandLess,
                        size: 20,
                        color: p.onSurfaceMuted,
                      ),
                    ),
                    const CancelAllDownloadsButton(),
                  ],
                ),
              ),
            ),
            if (_expanded)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .4,
                ),
                child: ListView(
                  key: const ValueKey('download-bar-list'),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in pending)
                      TrackTile(
                        title: item.title,
                        subtitle: downloadSubtitle(item),
                        tone: toneFor(item.id),
                        artwork: downloadThumbnail(item),
                        footer: Text(
                          downloadStatusText(l10n, item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: item.status == DownloadStatus.failed
                                ? p.onSurfaceMuted
                                : p.accent,
                          ),
                        ),
                        trailing: DownloadItemActions(item: item),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

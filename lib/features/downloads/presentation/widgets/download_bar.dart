import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../search/presentation/screens/media_detail_screen.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/download_queue_cubit.dart';
import 'download_item_widgets.dart';

/// 모든 탭 아래쪽(미니 플레이어 위)에 붙는 받기 줄. 두 영역으로 나뉜다.
/// - 위(작게): 전체 진행도 · 받은 곡 수 · 남은 곡 수 · 펼치기 · 전체 취소.
/// - 아래: 지금 받는 곡의 이미지 · 제목(길면 흐른다) · 아티스트 · 장르 · 진행도.
/// 위 줄을 누르면 아래로 나머지 대기 곡이 펼쳐지고, 곡을 누르면 그 곡의 상세 화면이 열린다.
/// 받는 곡이 없으면 아무것도 그리지 않는다. 유리는 이 띠 하나에만 쓰고, 곡 줄에는 쓰지 않는다.
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
    final others = [
      for (final i in pending)
        if (i.id != current.id) i,
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
            // 위 영역: 전체 현황.
            InkWell(
              key: const ValueKey('download-bar-toggle'),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xxs,
                  AppSpacing.xs,
                  AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    Text(
                      '${l10n.downloadsOverall(queue.doneCount, queue.items.length)}'
                      ' · ${l10n.downloadsRemaining(pending.length)}',
                      style: text.labelSmall?.copyWith(color: p.onSurfaceMuted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ProgressLine(
                        value: queue.overallProgress,
                        height: 2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Tooltip(
                      message: _expanded
                          ? l10n.downloadsCollapse
                          : l10n.downloadsExpand,
                      child: Icon(
                        _expanded ? AppIcons.expandMore : AppIcons.expandLess,
                        size: 18,
                        color: p.onSurfaceMuted,
                      ),
                    ),
                    const CancelAllDownloadsButton(),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: p.glassBorder),
            // 아래 영역: 지금 받는 곡.
            _DownloadRow(
              item: current,
              key: const ValueKey('download-current'),
            ),
            if (_expanded && others.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: p.glassBorder),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .3,
                ),
                child: ListView(
                  key: const ValueKey('download-bar-list'),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in others) _DownloadRow(item: item),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 받는 곡 한 줄: 이미지 · 제목(흐름) · 아티스트 · 장르 · 진행도. 누르면 그 곡의 상세 화면.
class _DownloadRow extends StatelessWidget {
  const _DownloadRow({super.key, required this.item});

  final DownloadItem item;

  void _openDetail(BuildContext context) => showMediaDetail(
    context,
    MediaHit(
      id: item.id,
      title: item.title,
      url: item.url,
      uploader: item.artist,
      duration: item.duration,
      thumbnailUrl: item.thumbnailUrl,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final failed = item.status == DownloadStatus.failed;
    final info = [
      if (item.artist.isNotEmpty) item.artist,
      if (item.genre.isNotEmpty) item.genre,
    ].join(' · ');

    return InkWell(
      onTap: () => _openDetail(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            _Thumb(item: item),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MarqueeText(item.title, style: text.titleSmall),
                  if (info.isNotEmpty)
                    Text(
                      info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: ProgressLine(
                          value: failed ? 0 : item.progress,
                          height: 3,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          downloadStatusText(l10n, item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: failed ? p.onSurfaceMuted : p.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DownloadItemActions(item: item),
          ],
        ),
      ),
    );
  }
}

/// 받는 곡의 이미지 (없으면 곡별 그라데이션 + 음표).
class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final art = downloadThumbnail(item);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: SizedBox.square(
        dimension: 52,
        child: art != null
            ? Image(image: art, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: context.tokens.glow(toneFor(item.id)),
                  ),
                ),
                child: Icon(
                  AppIcons.musicNote,
                  color: context.palette.onGlow,
                  size: 22,
                ),
              ),
      ),
    );
  }
}

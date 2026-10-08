import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../search/presentation/screens/media_detail_screen.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_source.dart';
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

  /// 지금 받는 곡 영역(이미지 · 제목 · 진행도)을 보일지. 접은 상태에서만 뜻이 있다.
  var _showCurrent = true;

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<DownloadQueueCubit>().state;
    final current = queue.current;
    if (current == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final muted = text.labelSmall?.copyWith(color: p.onSurfaceMuted);
    final cubit = context.read<DownloadQueueCubit>();
    final pending = [
      for (final i in queue.items)
        if (i.status != DownloadStatus.done) i,
    ];
    final allPaused = queue.allPaused;

    // 미니 플레이어와 같은 가로 전체 유리 띠. 강조색을 아주 옅게 깔아 자연스럽게 구분한다.
    return GlassSurface(
      key: const ValueKey('download-bar'),
      shape: const RoundedRectangleBorder(),
      rim: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.accent.withValues(alpha: .08),
          border: Border(
            top: BorderSide(color: p.accent.withValues(alpha: .35)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 위(작게): 전체 현황 · 전체 일시정지 · 전체 취소.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    '${l10n.downloadsOverall(queue.doneCount, queue.items.length)}'
                    ' · ${l10n.downloadsRemaining(pending.length)}',
                    style: muted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ProgressLine(
                      value: queue.overallProgress,
                      height: 2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CircleIconButton(
                    key: const ValueKey('download-pause-all'),
                    icon: allPaused ? AppIcons.play : AppIcons.pause,
                    tooltip: allPaused
                        ? l10n.downloadsResumeAll
                        : l10n.downloadsPauseAll,
                    size: 32,
                    onPressed: allPaused ? cubit.resumeAll : cubit.pauseAll,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const CancelAllDownloadsButton(),
                ],
              ),
            ),
            // 접었을 땐 지금 받는 곡, 펼치면 지금 곡까지 포함한 전체 목록.
            if (_expanded)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .35,
                ),
                child: ListView(
                  key: const ValueKey('download-bar-list'),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in pending) _DownloadRow(item: item),
                  ],
                ),
              )
            else if (_showCurrent)
              _DownloadRow(
                item: current,
                key: const ValueKey('download-current'),
              ),
            // 펼치기는 목록 바로 밑에. 접은 상태에선 받는 곡 정보를 숨길 수도 있다.
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const ValueKey('download-bar-toggle'),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _expanded
                                ? AppIcons.expandLess
                                : AppIcons.expandMore,
                            size: 18,
                            color: p.onSurfaceMuted,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _expanded
                                ? l10n.downloadsCollapse
                                : l10n.downloadsExpand,
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!_expanded)
                  InkWell(
                    key: const ValueKey('download-current-toggle'),
                    onTap: () => setState(() => _showCurrent = !_showCurrent),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        _showCurrent
                            ? l10n.downloadsHideCurrent
                            : l10n.downloadsShowCurrent,
                        style: muted,
                      ),
                    ),
                  ),
              ],
            ),
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

  /// 검색 결과와 같은 id(유튜브면 영상 id)로 만들어야 상세 화면의 미리 듣기 상태가 맞는다.
  String get _hitId {
    final key = downloadSourceKey(item.url);
    return key.startsWith('youtube:') ? key.substring(8) : item.url;
  }

  void _openDetail(BuildContext context) => showMediaDetail(
    context,
    MediaHit(
      id: _hitId,
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
          AppSpacing.md,
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
            const SizedBox(width: AppSpacing.sm),
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

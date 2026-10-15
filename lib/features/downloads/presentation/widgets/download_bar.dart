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

/// 받기 항목을 상세 화면이 여는 검색 결과로 바꾼다.
/// 검색 결과와 같은 id(유튜브면 영상 id)로 만들어야 상세 화면의 미리 듣기 상태가 맞는다.
MediaHit mediaHitOfDownload(DownloadItem item) {
  final key = downloadSourceKey(item.url);
  return MediaHit(
    id: key.startsWith('youtube:') ? key.substring(8) : item.url,
    title: item.title,
    url: item.url,
    uploader: item.artist,
    duration: item.duration,
    thumbnailUrl: item.thumbnailUrl,
  );
}

/// 모든 탭 아래쪽(미니 플레이어 위)에 붙는 받기 줄. 두 영역으로 나뉜다.
/// - 위(작게): 받은 곡 수 · 남은 곡 수 · 전체 진행도 · 일시정지 · 전체 취소 (누르면 펼침).
/// - 아래: 지금 받는 곡의 이미지 · 제목(길면 흐른다) · 아티스트 · 장르 · 진행도.
/// 위 줄을 누르면 아래로 나머지 대기 곡이 펼쳐지고, 곡을 누르면 그 곡의 상세 화면이 열린다.
/// 받는 곡이 없으면 아무것도 그리지 않는다. 유리는 이 띠 하나에만 쓰고, 곡 줄에는 쓰지 않는다.
class DownloadBar extends StatefulWidget {
  const DownloadBar({super.key, this.onMinimize});

  /// 위쪽 손잡이를 누르거나 아래로 쓸면 불린다 (플로팅 버튼으로 접기).
  final VoidCallback? onMinimize;

  @override
  State<DownloadBar> createState() => _DownloadBarState();
}

class _DownloadBarState extends State<DownloadBar> {
  var _expanded = false;

  /// 손잡이를 끌어 내리는 동안 띠가 손가락을 따라 내려간다 (놓으면 접히거나 제자리로 돌아간다).
  var _dragDy = 0.0;
  var _dragging = false;

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
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _dragDy),
      duration: _dragging ? Duration.zero : AppMotion.fast,
      curve: AppMotion.standard,
      builder: (context, dy, child) => Opacity(
        opacity: (1 - dy / 240).clamp(.35, 1.0),
        child: Transform.translate(offset: Offset(0, dy), child: child),
      ),
      child: GlassSurface(
        key: const ValueKey('download-bar'),
        shape: const RoundedRectangleBorder(),
        rim: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.accent.withValues(alpha: .06),
            border: Border(top: BorderSide(color: p.glassBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 손잡이: 누르거나 아래로 쓸면 플로팅 버튼으로 접힌다.
              GestureDetector(
                key: const ValueKey('download-minimize'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onMinimize,
                onVerticalDragStart: (_) => setState(() => _dragging = true),
                onVerticalDragUpdate: (d) => setState(
                  () => _dragDy = (_dragDy + d.delta.dy).clamp(0.0, 240.0),
                ),
                onVerticalDragEnd: (d) {
                  final fling = (d.primaryVelocity ?? 0) > 600;
                  if (_dragDy > 48 || fling) {
                    setState(() => _dragging = false);
                    widget.onMinimize?.call();
                  } else {
                    setState(() {
                      _dragging = false;
                      _dragDy = 0;
                    });
                  }
                },
                onVerticalDragCancel: () => setState(() {
                  _dragging = false;
                  _dragDy = 0;
                }),
                child: SizedBox(
                  height: 18,
                  width: double.infinity,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.onSurfaceMuted.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: const SizedBox(width: 36, height: 4),
                    ),
                  ),
                ),
              ),
              // 위(작게): 전체 현황 · 전체 일시정지 · 전체 취소. 현황을 누르면 목록이 펼쳐지고 접힌다.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const ValueKey('download-bar-toggle'),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${l10n.downloadsOverall(queue.doneCount, queue.items.length)}'
                                  ' · ${l10n.downloadsRemaining(pending.length)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: muted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              AnimatedRotation(
                                turns: _expanded ? .5 : 0,
                                duration: AppMotion.fast,
                                curve: AppMotion.standard,
                                child: Icon(
                                  AppIcons.expandLess,
                                  size: AppSizes.iconSm,
                                  color: p.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: ProgressLine(
                                  value: queue.overallProgress,
                                  height: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
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
              // 접었을 땐 지금 받는 곡, 펼치면 전체 목록. 높이 변화는 부드럽게 이어진다.
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .35,
                        ),
                        child: ListView.builder(
                          key: const ValueKey('download-bar-list'),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: pending.length,
                          itemBuilder: (_, i) => _DownloadRow(item: pending[i]),
                        ),
                      )
                    : _DownloadRow(
                        item: current,
                        key: const ValueKey('download-current'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 받는 곡 한 줄: 이미지 · 제목(흐름) · 아티스트 · 장르 · 진행도. 누르면 그 곡의 상세 화면.
class _DownloadRow extends StatelessWidget {
  const _DownloadRow({super.key, required this.item});

  final DownloadItem item;

  void _openDetail(BuildContext context) =>
      showMediaDetail(context, mediaHitOfDownload(item));

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
        dimension: 44,
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
                  size: AppSizes.icon,
                ),
              ),
      ),
    );
  }
}

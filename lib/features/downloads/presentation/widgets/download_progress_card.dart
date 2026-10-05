import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/download_queue_cubit.dart';

/// 검색창 아래 다운로드 영역: 주변 목록과 같은 얇은 테두리 카드 안에 받는 곡(이미지 · 진행 막대),
/// 지금 재생 중인 곡을 작게, 그 아래 화살표로 펼치는 대기 목록을 둔다.
/// 대기 목록은 곡 타일과 같은 모양이고 상태 글자는 없다.
class DownloadProgressCard extends StatefulWidget {
  const DownloadProgressCard({
    super.key,
    required this.current,
    required this.waiting,
    required this.onPlay,
  });

  final DownloadItem current;
  final List<DownloadItem> waiting;

  /// 대기열의 곡을 눌렀을 때 (재생할 수 있으면 재생한다).
  final ValueChanged<DownloadItem> onPlay;

  @override
  State<DownloadProgressCard> createState() => _DownloadProgressCardState();
}

class _DownloadProgressCardState extends State<DownloadProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final item = widget.current;
    final waiting = widget.waiting;

    return Material(
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(color: p.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 받는 곡: 이미지 · 제목 · 아티스트 · 진행 막대.
          TrackTile(
            title: item.title,
            subtitle: item.artist,
            tone: toneFor(item.id),
            artwork: _thumbnail(item),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressLine(value: item.progress, height: 4),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${l10n.statusDownloading} ${(item.progress * 100).round()}%',
                  style: text.labelSmall?.copyWith(color: p.accent),
                ),
              ],
            ),
            trailing: _CancelButton(item: item),
          ),
          const _NowPlayingStrip(),
          Divider(height: 1, thickness: 1, color: p.outline),
          InkWell(
            onTap: waiting.isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.downloadsWaiting(waiting.length),
                    style: text.labelMedium?.copyWith(color: p.onSurfaceMuted),
                  ),
                  const Spacer(),
                  if (waiting.isNotEmpty)
                    Tooltip(
                      message: _expanded
                          ? l10n.downloadsCollapse
                          : l10n.downloadsExpand,
                      child: AnimatedRotation(
                        turns: _expanded ? .5 : 0,
                        duration: AppMotion.fast,
                        child: Icon(
                          AppIcons.chevronDown,
                          color: p.onSurfaceMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      for (final w in waiting)
                        TrackTile(
                          title: w.title,
                          subtitle: w.artist,
                          tone: toneFor(w.id),
                          artwork: _thumbnail(w),
                          trailing: _CancelButton(item: w),
                          onTap: () => widget.onPlay(w),
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// 받는 곡의 썸네일. 없으면 곡 타일처럼 그라데이션 자리를 보여 준다.
  static ImageProvider? _thumbnail(DownloadItem item) {
    final url = item.thumbnailUrl;
    return url == null ? null : NetworkImage(url);
  }
}

/// 항목 하나를 대기열에서 뺀다.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) => CircleIconButton(
    icon: AppIcons.close,
    tooltip: context.l10n.actionCancel,
    size: 32,
    onPressed: () => context.read<DownloadQueueCubit>().cancel(item.id),
  );
}

/// 지금 재생 중인 곡을 작게 한 줄로. 재생 중인 곡이 없으면 숨긴다.
class _NowPlayingStrip extends StatelessWidget {
  const _NowPlayingStrip();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NowPlayingCubit>().state;
    final track = state.track;
    if (track == null) return const SizedBox.shrink();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            state.isPlaying ? AppIcons.equalizer : AppIcons.pause,
            size: 16,
            color: p.accent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '${track.title} · ${track.artist}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

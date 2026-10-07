import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/cached_web_image.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart'
    show imageOfCoverArt;
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../domain/entities/download_item.dart';
import '../bloc/download_queue_cubit.dart';

/// 검색창 아래 다운로드 영역: 지금 받는 곡 하나와 전체 진행도, 전체 취소 버튼만 보여 준다.
/// 곡별 진행은 그 곡이 담길 재생목록 상세에서 본다.
class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({
    super.key,
    required this.current,
    required this.total,
    required this.done,
    required this.progress,
  });

  final DownloadItem current;

  /// 대기열의 곡 수와 그중 끝난 곡 수.
  final int total;
  final int done;

  /// 전체 진행도 (0 ~ 1).
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final item = current;

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
          TrackTile(
            title: item.title,
            subtitle: downloadSubtitle(item),
            tone: toneFor(item.id),
            artwork: downloadThumbnail(item),
            footer: Text(
              downloadStatusText(l10n, item),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: item.status == DownloadStatus.failed
                    ? p.onSurfaceMuted
                    : p.accent,
              ),
            ),
            trailing: DownloadItemActions(item: item),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(child: ProgressLine(value: progress, height: 4)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.downloadsOverall(done, total),
                  style: text.labelMedium?.copyWith(color: p.onSurfaceMuted),
                ),
                const SizedBox(width: AppSpacing.xs),
                const CancelAllDownloadsButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 상태 글자: 받는 중 N% · 대기 · 일시정지 · 실패 (까닭).
String downloadStatusText(AppLocalizations l10n, DownloadItem item) =>
    switch (item.status) {
      DownloadStatus.failed =>
        item.error.isEmpty
            ? l10n.statusFailed
            : '${l10n.statusFailed} · ${item.error}',
      DownloadStatus.paused => l10n.statusPaused,
      DownloadStatus.queued => l10n.statusQueued,
      _ => '${l10n.statusDownloading} ${(item.progress * 100).round()}%',
    };

/// 아티스트 · 길이 (모르는 건 뺀다).
String downloadSubtitle(DownloadItem item) => [
  if (item.artist.isNotEmpty) item.artist,
  if (item.duration != null) formatDuration(item.duration!),
].join(' · ');

/// 받는 곡의 썸네일. 없으면 곡 타일처럼 그라데이션 자리를 보여 준다.
ImageProvider? downloadThumbnail(DownloadItem item) {
  if (item.cover case final art?) return imageOfCoverArt(art);
  final url = item.thumbnailUrl;
  return url == null ? null : CachedWebImage(url);
}

/// 끝나지 않은 받기를 모두 취소하는 버튼. 누르면 먼저 확인한다.
/// [playlistId]를 주면 그 재생목록에 담기로 한 곡만 취소한다.
class CancelAllDownloadsButton extends StatelessWidget {
  const CancelAllDownloadsButton({super.key, this.playlistId});

  final String? playlistId;

  @override
  Widget build(BuildContext context) => CircleIconButton(
    icon: AppIcons.close,
    tooltip: context.l10n.downloadsCancelAll,
    size: 32,
    onPressed: () => cancelAllDownloads(context, playlistId: playlistId),
  );
}

/// 확인을 받고 끝나지 않은 받기를 모두 취소한다.
Future<void> cancelAllDownloads(
  BuildContext context, {
  String? playlistId,
}) async {
  final queue = context.read<DownloadQueueCubit>();
  final count = playlistId == null
      ? queue.state.unfinishedCount
      : queue.state.unfinishedFor(playlistId).length;
  if (count == 0) return;
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialog) => AppDialog(
      title: context.l10n.downloadsCancelAllTitle,
      body: context.l10n.downloadsCancelAllBody(count),
      actions: [
        PillButton(
          label: context.l10n.downloadCancelKeep,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(dialog).pop(false),
        ),
        PillButton(
          label: context.l10n.downloadsCancelAll,
          icon: AppIcons.close,
          onPressed: () => Navigator.of(dialog).pop(true),
        ),
      ],
    ),
  );
  if (ok == true) await queue.cancelAll(playlistId: playlistId);
}

/// 실패한 항목은 다시 받기, 그 밖에는 취소.
class DownloadItemActions extends StatelessWidget {
  const DownloadItemActions({super.key, required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    if (item.status != DownloadStatus.failed) return _CancelButton(item: item);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleIconButton(
          icon: AppIcons.refresh,
          tooltip: context.l10n.actionRetry,
          size: 32,
          onPressed: () => context.read<DownloadQueueCubit>().retry(item.id),
        ),
        _CancelButton(item: item),
      ],
    );
  }
}

/// 항목 하나를 대기열에서 뺀다.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.item});

  final DownloadItem item;

  Future<void> _cancel(BuildContext context) async {
    final queue = context.read<DownloadQueueCubit>();
    if (item.isActive) {
      final ok = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (_) => _CancelDialog(title: item.title),
      );
      if (ok != true) return;
    }
    await queue.cancel(item.id);
  }

  @override
  Widget build(BuildContext context) => CircleIconButton(
    icon: AppIcons.close,
    tooltip: context.l10n.actionCancel,
    size: 32,
    onPressed: () => _cancel(context),
  );
}

class _CancelDialog extends StatelessWidget {
  const _CancelDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.downloadCancelTitle,
      body: l10n.downloadCancelBody(title),
      actions: [
        PillButton(
          label: l10n.downloadCancelKeep,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PillButton(
          label: l10n.downloadCancelConfirm,
          icon: AppIcons.close,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

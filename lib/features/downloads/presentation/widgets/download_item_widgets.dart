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
  Widget build(BuildContext context) => RowIconButton(
    // 곡 하나 취소(X)와 달라 보이게 "모두 비우기" 모양.
    icon: AppIcons.deleteAll,
    tooltip: context.l10n.downloadsCancelAll,
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
        RowIconButton(
          icon: AppIcons.refresh,
          tooltip: context.l10n.actionRetry,
          onPressed: () => context.read<DownloadQueueCubit>().retry(item.id),
        ),
        const SizedBox(width: AppSpacing.xs),
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
      final l10n = context.l10n;
      final ok = await showConfirmDialog(
        context,
        title: l10n.downloadCancelTitle,
        body: l10n.downloadCancelBody(item.title),
        confirmLabel: l10n.downloadCancelConfirm,
        cancelLabel: l10n.downloadCancelKeep,
      );
      if (!ok) return;
    }
    await queue.cancel(item.id);
  }

  @override
  Widget build(BuildContext context) => RowIconButton(
    icon: AppIcons.close,
    tooltip: context.l10n.actionCancel,
    onPressed: () => _cancel(context),
  );
}

import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/sample/sample_data.dart';
import '../../library/domain/track.dart';

enum DownloadStatus { downloading, queued, paused, failed, done }

class _Item {
  const _Item(this.track, this.status, this.progress);

  final Track track;
  final DownloadStatus status;
  final double progress;
}

/// 다운로드 대기열 (상세 기능: 다운로드 대기열 #7). 자리 표시 데이터.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static final _items = [
    _Item(SampleData.tracks[3], DownloadStatus.downloading, .72),
    _Item(SampleData.tracks[4], DownloadStatus.downloading, .31),
    _Item(SampleData.tracks[5], DownloadStatus.queued, 0),
    _Item(SampleData.tracks[6], DownloadStatus.queued, 0),
    _Item(SampleData.tracks[7], DownloadStatus.paused, .45),
    _Item(SampleData.tracks[8], DownloadStatus.failed, .12),
    _Item(SampleData.tracks[9], DownloadStatus.done, 1),
    _Item(SampleData.tracks[10], DownloadStatus.done, 1),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = _items
        .where((i) => i.status == DownloadStatus.downloading)
        .toList();
    final waiting = _items
        .where((i) => i.status == DownloadStatus.queued)
        .length;
    final overall = active.isEmpty
        ? 0.0
        : active.map((i) => i.progress).reduce((a, b) => a + b) / active.length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          AppTopBar(
            large: true,
            title: l10n.navDownloads,
            subtitle: l10n.downloadsSubtitle,
            actions: [
              CircleIconButton(
                icon: Icons.pause_rounded,
                tooltip: l10n.downloadsPauseAll,
                onPressed: () {},
              ),
              CircleIconButton(
                icon: Icons.clear_all_rounded,
                tooltip: l10n.downloadsClearDone,
                onPressed: () {},
              ),
            ],
          ),
          Padding(
            padding: AppSpacing.screen,
            child: GlowCard(
              tone: GlowTone.tertiary,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.downloadsActive,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DotMatrixText('${active.length}', dotSize: 7, gap: 2.5),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.downloadsWaiting(waiting),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.palette.onSurface),
                        ),
                      ],
                    ),
                  ),
                  DottedProgressArc(
                    value: overall,
                    size: 120,
                    dotCount: 36,
                    child: DotMatrixText(
                      '${(overall * 100).round()}%',
                      dotSize: 3,
                      gap: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in _items) _DownloadTile(item: item),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final (label, emphasized) = switch (item.status) {
      DownloadStatus.downloading => (
        '${l10n.statusDownloading} ${(item.progress * 100).round()}%',
        true,
      ),
      DownloadStatus.queued => (l10n.statusQueued, false),
      DownloadStatus.paused => (l10n.statusPaused, false),
      DownloadStatus.failed => (l10n.statusFailed, false),
      DownloadStatus.done => (l10n.statusDone, false),
    };

    final action = switch (item.status) {
      DownloadStatus.downloading => CircleIconButton(
        icon: Icons.pause_rounded,
        tooltip: l10n.actionPause,
        onPressed: () {},
      ),
      DownloadStatus.paused => CircleIconButton(
        icon: Icons.play_arrow_rounded,
        tooltip: l10n.actionResume,
        onPressed: () {},
      ),
      DownloadStatus.failed => CircleIconButton(
        icon: Icons.refresh_rounded,
        tooltip: l10n.actionRetry,
        emphasized: true,
        onPressed: () {},
      ),
      DownloadStatus.queued => CircleIconButton(
        icon: Icons.close_rounded,
        tooltip: l10n.actionCancel,
        onPressed: () {},
      ),
      DownloadStatus.done => Icon(Icons.check_circle_rounded, color: p.accent),
    };

    final showBar =
        item.status == DownloadStatus.downloading ||
        item.status == DownloadStatus.paused;

    return TrackTile(
      title: item.track.title,
      subtitle: item.track.artist,
      tone: toneFor(item.track.id),
      trailing: action,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBar) ...[
            DottedProgressBar(value: item.progress, height: 3, spacing: 6),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            label,
            style: text.labelMedium?.copyWith(
              color: emphasized ? p.accent : p.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

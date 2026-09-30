import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/download_item.dart';

/// 검색창 아래 다운로드 카드: 받는 곡의 썸네일을 배경으로 깔고 어둡게 덮는다.
/// 아래 화살표로 대기 중인 곡 목록을 펼친다.
class DownloadProgressCard extends StatefulWidget {
  const DownloadProgressCard({
    super.key,
    required this.current,
    required this.waiting,
  });

  final DownloadItem current;
  final List<DownloadItem> waiting;

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
    final onImage = p.onGlow;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Stack(
        children: [
          Positioned.fill(child: _Thumbnail(item: item)),
          Positioned.fill(
            child: ColoredBox(color: p.scrim.withValues(alpha: .6)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.statusDownloading} ${(item.progress * 100).round()}%',
                  style: text.labelMedium?.copyWith(color: p.accent),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(color: onImage),
                ),
                Text(
                  item.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: onImage.withValues(alpha: .75),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ProgressLine(value: item.progress, height: 4),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: waiting.isEmpty
                      ? null
                      : () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l10n.downloadsWaiting(waiting.length),
                          style: text.labelMedium?.copyWith(
                            color: onImage.withValues(alpha: .85),
                          ),
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
                                Icons.keyboard_arrow_down_rounded,
                                color: onImage,
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
                              _WaitingRow(item: w, color: onImage),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final glow = context.tokens.glow(toneFor(item.id));
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-.6, -.7),
          radius: 1.6,
          colors: glow,
          stops: const [0, .5, 1],
        ),
      ),
    );
    final url = item.thumbnailUrl;
    if (url == null) return gradient;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => gradient,
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({required this.item, required this.color});

  final DownloadItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final status = item.status == DownloadStatus.paused
        ? l10n.statusPaused
        : l10n.statusQueued;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.title} · ${item.artist}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status,
            style: text.labelSmall?.copyWith(
              color: color.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }
}

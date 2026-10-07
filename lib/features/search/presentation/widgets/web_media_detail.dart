import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/presentation/widgets/download_dialog.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../domain/entities/media_info.dart';
import '../../domain/entities/media_site.dart';
import 'preview_control.dart';

/// 유튜브가 아닌 사이트(웹 검색 결과)의 곡 상세.
/// 유튜브 상세(가로 썸네일 · 채널 줄 · 표)와 달리, 어느 사이트인지를 맨 위에 보여 주고
/// 앨범처럼 정사각 커버 아래에 제목 · 아티스트를 가운데로 놓는다.
class WebMediaDetail extends StatelessWidget {
  const WebMediaDetail({
    super.key,
    required this.hit,
    required this.loading,
    required this.onOpen,
    required this.onBack,
  });

  final MediaHit hit;
  final bool loading;

  /// 주소를 기기의 다른 앱(브라우저)으로 연다.
  final void Function(String url) onOpen;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final locale = Localizations.localeOf(context).toString();
    final site = MediaSite.fromUrl(hit.url);
    final compact = NumberFormat.compact(locale: locale);

    // 길이 · 재생 수 · 좋아요 · 올린 날을 한 줄로 이어 보여 준다 (표로 나누지 않는다).
    final facts = <String>[
      if (hit.duration != null) formatDuration(hit.duration!),
      if (hit.viewCount != null)
        l10n.mediaDetailViewCount(compact.format(hit.viewCount)),
      if (hit.likeCount != null)
        '${l10n.mediaDetailLikes} ${compact.format(hit.likeCount)}',
      if (hit.uploadedAt != null)
        MaterialLocalizations.of(context).formatCompactDate(hit.uploadedAt!),
    ];

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.mediaDetailTitle,
                leading: CircleIconButton(
                  icon: AppIcons.back,
                  tooltip: l10n.actionBack,
                  onPressed: onBack,
                ),
              ),
              SizedBox(
                height: 2,
                child: loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : null,
              ),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
                  children: [
                    _SiteBadge(site: site),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: ArtworkBox(
                        key: const ValueKey('web-detail-cover'),
                        image: hit.thumbnailUrl == null
                            ? null
                            : NetworkImage(hit.thumbnailUrl!),
                        size: 220,
                        radius: AppRadii.lg,
                        tone: toneFor(hit.id),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      hit.title,
                      style: text.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (hit.uploader.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hit.uploader,
                        key: const ValueKey('web-detail-artist'),
                        style: text.bodyLarge?.copyWith(color: p.primary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        facts.join(' · '),
                        style: text.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Center(child: PreviewButton(hit: hit)),
                    PreviewProgressBar(hitId: hit.id, showTime: true),
                    if (hit.channelUrl != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: PlainButton(
                          key: const ValueKey('web-detail-artist-page'),
                          label: l10n.mediaDetailOpenArtist,
                          icon: AppIcons.openInNew,
                          accent: true,
                          onPressed: () => onOpen(hit.channelUrl!),
                        ),
                      ),
                    ],
                    if (hit.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.mediaDetailDescription, style: text.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hit.description,
                        style: text.bodyMedium?.copyWith(
                          color: p.onSurfaceMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        key: const ValueKey('detail-watch'),
                        label: site.name.isEmpty
                            ? l10n.mediaDetailOpenOriginal
                            : l10n.mediaDetailOpenSite(site.name),
                        icon: AppIcons.openInNew,
                        onPressed: () => onOpen(hit.url),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PillButton(
                      key: const ValueKey('detail-download'),
                      label: l10n.actionDownload,
                      icon: AppIcons.download,
                      variant: PillVariant.tonal,
                      onPressed: () => showDownloadDialog(
                        context,
                        title: hit.title,
                        artist: hit.uploader,
                        duration: hit.duration,
                        thumbnailUrl: hit.thumbnailUrl,
                        url: hit.url,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 맨 위의 출처 표시: 사이트 아이콘 · 사이트 이름 · "웹 검색 결과".
class _SiteBadge extends StatelessWidget {
  const _SiteBadge({required this.site});

  final MediaSite site;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Row(
      key: const ValueKey('web-detail-site'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.globe, size: 20, color: p.primary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            site.name,
            style: text.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('· ${context.l10n.mediaDetailWebBadge}', style: text.bodySmall),
      ],
    );
  }
}

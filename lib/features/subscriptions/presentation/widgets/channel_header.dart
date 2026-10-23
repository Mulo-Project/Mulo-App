import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 채널 시트 맨 위: 배너 · 이미지 · 이름 · 구독자 수 (· 영상 수) · 소개.
/// 채널 정보 시트와 구독 채널 옵션 시트가 같은 모양으로 쓴다.
/// 배너 · 구독자 수 · 소개 전체는 읽어 온 뒤에 채워진다 (못 읽으면 있는 것만 보인다).
class ChannelHeader extends StatelessWidget {
  const ChannelHeader({
    super.key,
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.bannerUrl,
    this.subscriberCount,
    this.videoCount,
    this.description = '',
  });

  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? bannerUrl;
  final int? subscriberCount;
  final int? videoCount;
  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final meta = [
      if (subscriberCount != null)
        l10n.mediaDetailSubscribers(
          NumberFormat.compact(locale: locale).format(subscriberCount),
        ),
      if (videoCount != null && videoCount! > 0)
        l10n.channelInfoVideoCount(videoCount!),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bannerUrl != null) ...[
          ChannelBanner(url: bannerUrl!),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            ArtworkBox(
              image: thumbnailUrl == null ? null : NetworkImage(thumbnailUrl!),
              size: 64,
              radius: 32,
              tone: toneFor(id),
              icon: AppIcons.person,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.hair),
                    Text(
                      meta,
                      style: text.bodyMedium?.copyWith(
                        color: context.palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ExpandableText(description, collapsedLines: 3),
        ],
      ],
    );
  }
}

/// 채널 배너: 가로로 긴 이미지를 둥근 모서리로 보여 준다. 못 불러오면 자리를 비운다.
class ChannelBanner extends StatelessWidget {
  const ChannelBanner({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.md),
    child: AspectRatio(
      aspectRatio: 16 / 5,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
          opacity: frame == null && !sync ? 0 : 1,
          duration: AppMotion.medium,
          child: child,
        ),
      ),
    ),
  );
}

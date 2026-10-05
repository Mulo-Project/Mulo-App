import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/presentation/widgets/download_dialog.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../domain/entities/media_info.dart';
import '../../domain/usecases/search_usecases.dart';
import '../bloc/media_detail_cubit.dart';
import '../widgets/video_category.dart';

/// 검색 결과 하나의 상세 보기: 큰 썸네일, 채널, 길이 · 조회수 · 올린 날 · 분류 · 설명.
/// 영상 보기와 채널 보기는 기기의 유튜브 앱(없으면 브라우저)으로 연다.
/// 탭 틀 위로 덮어 열린다 ([showMediaDetail]).
Future<void> showMediaDetail(BuildContext context, MediaHit hit) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<void>(MaterialPageRoute(builder: (_) => MediaDetailScreen(hit: hit)));
}

/// 유튜브 주소인가 (영상 보기 문구를 "유튜브에서 보기"로 하려고).
bool isYoutubeUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host == 'youtu.be' ||
      host == 'youtube.com' ||
      host.endsWith('.youtube.com');
}

class MediaDetailScreen extends StatelessWidget {
  const MediaDetailScreen({super.key, required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MediaDetailCubit(
      hit,
      sl<FetchMediaInfo>(),
      sl<FetchChannelInfo>(),
      sl<OpenLink>(),
    )..load(),
    child: const _DetailView(),
  );
}

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  Future<void> _open(String url) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await context.read<MediaDetailCubit>().open(url);
    if (opened) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.mediaDetailOpenFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final state = context.watch<MediaDetailCubit>().state;
    final hit = state.hit;
    final locale = Localizations.localeOf(context).toString();
    final youtube = isYoutubeUrl(hit.url);

    final views = hit.viewCount;
    final uploaded = hit.uploadedAt;
    final rows = <(String, String)>[
      if (hit.duration != null)
        (l10n.mediaDetailDuration, formatDuration(hit.duration!)),
      if (views != null)
        (
          l10n.mediaDetailViews,
          l10n.mediaDetailViewCount(
            NumberFormat.compact(locale: locale).format(views),
          ),
        ),
      if (hit.likeCount != null)
        (
          l10n.mediaDetailLikes,
          NumberFormat.compact(locale: locale).format(hit.likeCount),
        ),
      if (uploaded != null)
        (
          l10n.mediaDetailUploaded,
          MaterialLocalizations.of(context).formatCompactDate(uploaded),
        ),
      if (hit.categories.isNotEmpty)
        (
          l10n.mediaDetailCategory,
          hit.categories.map((c) => categoryLabel(l10n, c)).join(' · '),
        ),
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(
                height: 2,
                child: state.loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : null,
              ),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
                  children: [
                    _Thumbnail(hit: hit, onPlay: () => _open(hit.url)),
                    const SizedBox(height: AppSpacing.md),
                    Text(hit.title, style: text.titleLarge),
                    if (hit.uploader.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ChannelRow(
                        hit: hit,
                        subscribers: hit.subscriberCount == null
                            ? null
                            : l10n.mediaDetailSubscribers(
                                NumberFormat.compact(locale: locale)
                                    .format(hit.subscriberCount),
                              ),
                        onOpen: hit.channelUrl == null
                            ? null
                            : () => _open(hit.channelUrl!),
                      ),
                    ],
                    if (rows.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Divider(height: 1, color: p.outline),
                      for (final (label, value) in rows) ...[
                        _InfoRow(label: label, value: value),
                        Divider(height: 1, color: p.outline),
                      ],
                    ],
                    if (hit.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.mediaDetailDescription, style: text.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      _Description(hit.description),
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
                        label: youtube
                            ? l10n.mediaDetailWatchYoutube
                            : l10n.mediaDetailOpenOriginal,
                        icon: AppIcons.play,
                        onPressed: () => _open(hit.url),
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

/// 썸네일 높이 상한.
const _maxThumbHeight = 260.0;

/// 16:9 썸네일. 가운데 재생 버튼을 누르면 영상을 연다.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.hit, required this.onPlay});

  final MediaHit hit;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final thumb = hit.thumbnailUrl;
    return LayoutBuilder(
      builder: (context, box) {
        // 넓은 화면(데스크톱)에서 너무 커지지 않게 높이를 제한하고 가운데에 둔다.
        final width = math.min(box.maxWidth, _maxThumbHeight * 16 / 9);
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ArtworkBox(
                image: thumb == null ? null : NetworkImage(thumb),
                size: width * 9 / 16,
                width: width,
                radius: AppRadii.md,
                tone: toneFor(hit.id),
              ),
              CircleIconButton(
                icon: AppIcons.play,
                tooltip: context.l10n.mediaDetailWatchYoutube,
                emphasized: true,
                size: AppSizes.circleButtonLarge,
                onPressed: onPlay,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                color: context.palette.onSurfaceMuted,
              ),
            ),
          ),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
  }
}

/// 채널 줄: 채널 이미지 · 이름 · 구독자 수, 오른쪽에 채널 보기.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.hit, this.subscribers, this.onOpen});

  final MediaHit hit;
  final String? subscribers;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final image = hit.channelThumbnailUrl;
    return Row(
      children: [
        ArtworkBox(
          key: const ValueKey('detail-channel-image'),
          image: image == null ? null : NetworkImage(image),
          size: 44,
          radius: 22,
          tone: toneFor(hit.uploader),
          icon: AppIcons.person,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hit.uploader,
                style: text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subscribers != null)
                Text(
                  subscribers!,
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (onOpen != null)
          PlainButton(
            label: context.l10n.mediaDetailOpenChannel,
            icon: AppIcons.openInNew,
            accent: true,
            onPressed: onOpen,
          ),
      ],
    );
  }
}

/// 영상 설명: 4줄까지 보이고, 그보다 길 때만 "더 보기"가 나온다.
/// 설명 글이나 버튼을 누르면 펼치고 접는다.
class _Description extends StatefulWidget {
  const _Description(this.text);

  final String text;

  static const collapsedLines = 4;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.palette.onSurfaceMuted);

    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _Description.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: box.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        final body = AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topLeft,
          child: Text(
            widget.text,
            style: style,
            maxLines: _open || !overflows ? null : _Description.collapsedLines,
            overflow: _open || !overflows
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        );
        if (!overflows) return body;

        void toggle() => setState(() => _open = !_open);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggle,
              child: body,
            ),
            PlainButton(
              key: const ValueKey('detail-description-toggle'),
              label: _open ? l10n.mediaDetailLess : l10n.mediaDetailMore,
              icon: _open ? AppIcons.chevronUp : AppIcons.chevronDown,
              onPressed: toggle,
            ),
          ],
        );
      },
    );
  }
}

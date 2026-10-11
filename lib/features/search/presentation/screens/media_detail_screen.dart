import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/presentation/widgets/download_dialog.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../../subscriptions/presentation/widgets/subscribe_button.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/usecases/search_usecases.dart';
import '../bloc/media_detail_cubit.dart';
import '../bloc/preview_cubit.dart';
import '../widgets/preview_control.dart';
import '../widgets/video_category.dart';
import '../widgets/youtube_embed.dart';

/// 검색 결과 하나의 상세 보기: 큰 썸네일, 채널, 길이 · 조회수 · 올린 날 · 분류 · 설명.
/// 영상 보기와 채널 보기는 기기의 유튜브 앱(없으면 브라우저)으로 연다.
/// 탭 틀 위로 덮어 열린다 ([showMediaDetail]).
Future<void> showMediaDetail(BuildContext context, MediaHit hit) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<void>(MaterialPageRoute(builder: (_) => MediaDetailScreen(hit: hit)));
}

/// SoundCloud 주소인가 (음원 사이트라 영상이 아니라 커버 · 아티스트 모양으로 보여 주려고).
bool isSoundcloudUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host == 'soundcloud.com' || host.endsWith('.soundcloud.com');
}

/// 유튜브 주소인가 (영상 보기 문구를 "유튜브에서 보기"로 하려고).
bool isYoutubeUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host == 'youtu.be' ||
      host == 'youtube.com' ||
      host.endsWith('.youtube.com');
}

class MediaDetailScreen extends StatelessWidget {
  const MediaDetailScreen({
    super.key,
    required this.hit,
    @visibleForTesting this.inAppVideo,
    @visibleForTesting this.playerBuilder,
  });

  final MediaHit hit;

  /// 앱 안 재생 가능 여부를 바꿔 쓴다 (테스트용, 기본은 플랫폼에 따른다).
  final bool? inAppVideo;

  /// 앱 안 플레이어를 바꿔 쓴다 (테스트용, 기본은 [YoutubeEmbedPlayer]).
  final Widget Function(String videoId, VoidCallback onFailed)? playerBuilder;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MediaDetailCubit(
      hit,
      sl<FetchMediaInfo>(),
      sl<FetchChannelInfo>(),
      sl<OpenLink>(),
    )..load(),
    child: _DetailView(
      inAppVideo: inAppVideo ?? inAppVideoSupported,
      playerBuilder: playerBuilder,
    ),
  );
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.inAppVideo, this.playerBuilder});

  final bool inAppVideo;
  final Widget Function(String videoId, VoidCallback onFailed)? playerBuilder;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  late final PreviewCubit _preview;

  @override
  void initState() {
    super.initState();
    _preview = context.read<PreviewCubit>();
  }

  /// 앱 안에서 영상을 틀고 있는지 / 틀어 보려다 막혀서 유튜브로만 열 수 있는지.
  bool _playing = false;
  bool _embedBlocked = false;

  Future<void> _open(String url) async {
    // 영상 · 채널은 다른 앱으로 열리니 미리 듣기 소리가 겹치지 않게 멈춘다.
    _preview.stop();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await context.read<MediaDetailCubit>().open(url);
    if (opened) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.mediaDetailOpenFailed)));
  }

  /// 이 영상을 앱 안에서 틀어 볼 수 있는가 (Android 유튜브 영상, 아직 막힌 적 없음).
  bool _canEmbed(MediaHit hit) =>
      widget.inAppVideo &&
      !_embedBlocked &&
      isYoutubeUrl(hit.url) &&
      isYoutubeVideoId(hit.id);

  /// 썸네일의 재생 버튼: 앱 안에서 틀 수 있으면 그 자리에서, 아니면 유튜브로 연다.
  void _play(MediaHit hit) {
    if (!_canEmbed(hit)) return unawaited(_open(hit.url));
    // 앱 안 영상과 미리 듣기 소리가 겹치지 않게 미리 듣기는 멈춘다.
    _preview.stop();
    setState(() => _playing = true);
  }

  /// 임베드가 막힌(또는 못 불러온) 영상은 앱 안 재생을 접고 유튜브로 열게 한다.
  void _onEmbedFailed() => setState(() {
    _playing = false;
    _embedBlocked = true;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final state = context.watch<MediaDetailCubit>().state;
    final hit = state.hit;
    final locale = Localizations.localeOf(context).toString();
    final youtube = isYoutubeUrl(hit.url);
    // 유튜브가 아닌 곳(SoundCloud 등)은 영상이 아니라 음원이다: 커버 · 아티스트 · 재생수로 보여 준다.
    final audio = !youtube;

    final views = hit.viewCount;
    final uploaded = hit.uploadedAt;
    final rows = <(String, String)>[
      if (hit.duration != null)
        (l10n.mediaDetailDuration, formatDuration(hit.duration!)),
      if (views != null)
        (
          audio ? l10n.mediaDetailPlays : l10n.mediaDetailViews,
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
      if (hit.creators.length > 1)
        (
          l10n.mediaDetailCollaborators,
          // 대표 채널은 위 채널 줄에 있어서 나머지 공동 작업자만 적는다.
          hit.creators.where((c) => c != hit.uploader).join(' · '),
        ),
      if (hit.categories.isNotEmpty)
        (
          audio ? l10n.mediaDetailGenre : l10n.mediaDetailCategory,
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
                    if (_playing && _canEmbed(hit))
                      (widget.playerBuilder ??
                          (id, onFailed) => YoutubeEmbedPlayer(
                            key: ValueKey('embed-$id'),
                            videoId: id,
                            onFailed: (_) => onFailed(),
                          ))(hit.id, _onEmbedFailed)
                    else
                      _Thumbnail(
                        hit: hit,
                        inApp: _canEmbed(hit),
                        audio: audio,
                        onPlay: () => _play(hit),
                      ),
                    if (_embedBlocked)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Row(
                          key: const ValueKey('detail-embed-blocked'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              AppIcons.info,
                              size: 18,
                              color: p.onSurfaceMuted,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                l10n.mediaDetailEmbedBlocked,
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(child: PreviewButton(hit: hit)),
                    PreviewProgressBar(hitId: hit.id, showTime: true),
                    const SizedBox(height: AppSpacing.md),
                    Text(hit.title, style: text.titleLarge),
                    if (hit.uploader.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ChannelRow(
                        hit: hit,
                        audio: audio,
                        subscribers: hit.subscriberCount == null
                            ? null
                            : (audio
                                  ? l10n.mediaDetailFollowers
                                  : l10n.mediaDetailSubscribers)(
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
                            : isSoundcloudUrl(hit.url)
                            ? l10n.mediaDetailListenSoundcloud
                            : l10n.mediaDetailListenOriginal,
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

/// 썸네일 높이 상한.
const _maxThumbHeight = 260.0;

/// 16:9 썸네일(음원이면 정사각형 커버). 가운데 재생 버튼을 누르면 영상(음원은 원본 페이지)을 연다.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.hit,
    required this.onPlay,
    this.inApp = false,
    this.audio = false,
  });

  final MediaHit hit;

  /// 음원(영상이 아님): 정사각형 커버로 보여 준다.
  final bool audio;

  /// 앱 안에서 재생되는 버튼인가 (툴팁 문구만 다르다).
  final bool inApp;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final thumb = hit.thumbnailUrl;
    return LayoutBuilder(
      builder: (context, box) {
        // 넓은 화면(데스크톱)에서 너무 커지지 않게 높이를 제한하고 가운데에 둔다.
        final width = audio
            ? math.min(box.maxWidth, _maxThumbHeight)
            : math.min(box.maxWidth, _maxThumbHeight * 16 / 9);
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ArtworkBox(
                image: thumb == null ? null : NetworkImage(thumb),
                size: audio ? width : width * 9 / 16,
                width: width,
                radius: AppRadii.md,
                tone: toneFor(hit.id),
              ),
              CircleIconButton(
                icon: AppIcons.play,
                tooltip: inApp
                    ? context.l10n.mediaDetailPlayInApp
                    : audio
                    ? context.l10n.mediaDetailListenOriginal
                    : context.l10n.mediaDetailWatchYoutube,
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
  const _ChannelRow({
    required this.hit,
    this.audio = false,
    this.subscribers,
    this.onOpen,
  });

  final MediaHit hit;

  /// 음원이면 "채널 보기" 대신 "아티스트 보기".
  final bool audio;
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
              // 긴 채널 이름은 잘라 내지 않고 옆으로 흘려 끝까지 보여 준다.
              MarqueeText(hit.uploader, style: text.titleSmall),
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
        if (!audio)
          SubscribeButton(
            channelUrl: hit.channelUrl,
            name: hit.uploader,
            thumbnailUrl: hit.channelThumbnailUrl,
          ),
        if (onOpen != null)
          PlainButton(
            label: audio
                ? context.l10n.mediaDetailOpenArtist
                : context.l10n.mediaDetailOpenChannel,
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
            Center(
              child: PlainButton(
                key: const ValueKey('detail-description-toggle'),
                label: _open ? l10n.mediaDetailLess : l10n.mediaDetailMore,
                icon: _open ? AppIcons.chevronUp : AppIcons.chevronDown,
                onPressed: toggle,
              ),
            ),
          ],
        );
      },
    );
  }
}

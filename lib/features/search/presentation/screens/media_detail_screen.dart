import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/presentation/widgets/download_dialog.dart';
import '../../../library/domain/entities/track.dart' show Track, formatDuration;
import '../../../subscriptions/presentation/widgets/subscribe_button.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/usecases/search_usecases.dart';
import '../bloc/audio_language_cubit.dart';
import '../bloc/media_detail_cubit.dart';
import '../bloc/media_hit_memo.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/preview_cubit.dart';
import '../saved_track.dart';
import '../bloc/saved_videos_cubit.dart';
import '../bloc/stream_cache_cubit.dart';
import '../bloc/video_quality_cubit.dart';
import '../../domain/entities/video_quality.dart';
import '../widgets/video_quality_sheet.dart';
import '../widgets/audio_language_sheet.dart';
import 'saved_videos_screen.dart' show savedVideosLocation;
import '../widgets/preview_control.dart';
import '../widgets/saved_queue_controls.dart';
import '../widgets/preview_video.dart';
import '../widgets/preview_video_controls.dart';
import '../widgets/video_category.dart';
import '../widgets/youtube_embed.dart';

/// 상세 화면의 경로 이름. 같은 영상의 상세 화면이 이미 맨 위에 있는지 알아볼 때 쓴다.
String mediaDetailRouteName(String hitId) => 'media-detail:$hitId';

/// 검색 결과 하나의 상세 보기: 큰 썸네일, 채널, 길이 · 조회수 · 올린 날 · 분류 · 설명.
/// 영상 보기와 채널 보기는 기기의 유튜브 앱(없으면 브라우저)으로 연다.
/// 탭 틀 위로 덮어 열린다 ([showMediaDetail]).
Future<void> showMediaDetail(BuildContext context, MediaHit hit) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      settings: RouteSettings(name: mediaDetailRouteName(hit.id)),
      builder: (_) => MediaDetailScreen(hit: hit),
    ),
  );
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

/// 웹 항목에 보여 줄 사이트 이름: 주소의 도메인에서 앞의 `www.`를 뺀 것 (모르면 빈 문자열).
String siteNameOf(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host.startsWith('www.') ? host.substring(4) : host;
}

class MediaDetailScreen extends StatelessWidget {
  const MediaDetailScreen({
    super.key,
    required this.hit,
    @visibleForTesting this.inAppVideo,
    @visibleForTesting this.playerBuilder,
    this.fromSaved = false,
  });

  final MediaHit hit;

  /// 저장한 음원 화면에서 열었다: 아래에 재생 목록 조작부를 늘 붙인다 (검색의 받기용 타일에서 연 상세와 다르다).
  final bool fromSaved;

  /// 앱 안 재생 가능 여부를 바꿔 쓴다 (테스트용, 기본은 플랫폼에 따른다).
  final bool? inAppVideo;

  /// 앱 안 플레이어를 바꿔 쓴다 (테스트용, 기본은 [YoutubeEmbedPlayer]).
  final Widget Function(String videoId, VoidCallback onFailed)? playerBuilder;

  @override
  Widget build(BuildContext context) {
    // 저장한 곡이면 저장해 둔 상세 정보를 먼저 쓴다 (검색 목록에서 들어와도 다시 읽지 않는다).
    MediaHit? savedHit;
    try {
      savedHit = context
          .read<SavedVideosCubit>()
          .state
          .where((v) => v.id == hit.id)
          .firstOrNull
          ?.hit;
    } on Object {
      savedHit = null;
    }
    return _build(savedHit);
  }

  Widget _build(MediaHit? savedHit) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => MediaDetailCubit(
          savedHit ?? hit,
          sl<FetchMediaInfo>(),
          sl<FetchChannelInfo>(),
          sl<OpenLink>(),
          memo: sl<MediaHitMemo>(),
          stored: savedHit != null,
        )..load(),
      ),
      // 유튜브 곡만 오디오 언어가 여럿일 수 있다.
      BlocProvider(
        create: (context) {
          final cubit = sl<AudioLanguageCubit>();
          if (isYoutubeUrl(hit.url)) {
            cubit.load(hit.url);
            context.read<PreviewCubit>().prefetch(hit);
          }
          return cubit;
        },
      ),
    ],
    child: _DetailView(
      inAppVideo: inAppVideo ?? inAppVideoSupported,
      playerBuilder: playerBuilder,
      fromSaved: fromSaved,
    ),
  );
}

class _DetailView extends StatefulWidget {
  const _DetailView({
    required this.inAppVideo,
    this.playerBuilder,
    this.fromSaved = false,
  });

  final bool inAppVideo;
  final bool fromSaved;
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

  /// 듣는 중에 오디오 언어를 바꾸면 고른 언어로 처음부터 다시 듣는다.
  Future<void> _restartPreview(MediaHit hit, String language) async {
    if (!_preview.state.isActive(hit.id)) return;
    await _preview.stop();
    if (!mounted) return;
    await togglePreview(context, hit, audioLanguage: language);
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

  /// 저장한 음원 화면에서 연 상세에서 처음 재생: 메인 재생 대기열로 시작한다 (영상으로 저장한 곡은 영상으로 나온다).
  Future<void> _startSaved(MediaHit hit) async {
    final now = context.read<NowPlayingCubit>();
    final saved = context.read<SavedVideosCubit>().state;
    final at = saved.indexWhere((v) => v.id == hit.id);
    final ready = at >= 0 && saved[at].ready;
    // 두 소리가 겹치지 않게 미리 듣기는 멈추고, 메인 재생 대기열로 시작한다.
    await _preview.stop();
    if (!ready) {
      // 아직 다 받지 못한 곡은 한 곡만 미리 듣기로 튼다.
      unawaited(
        _preview.toggle(hit, videoQuality: at < 0 ? null : saved[at].quality),
      );
      return;
    }
    final tracks = await savedTracksResolved(saved);
    final index = tracks.indexWhere(
      (t) => t.id == '${Track.savedIdPrefix}${hit.id}',
    );
    if (tracks.isEmpty) return;
    now.playQueue(tracks, index: index < 0 ? 0 : index);
  }

  /// 썸네일의 재생 버튼: 앱 안에서 틀 수 있는 유튜브 영상은 미리 듣기(소리 + 영상)로 그 자리에서 튼다.
  /// 그 화면을 나가면 미니 플레이어가 영상을 이어서 보여 준다.
  /// 미리 듣기를 시작하지 못하면 앱 안 플레이어(웹뷰)로, 그것도 안 되면 유튜브로 연다.
  Future<void> _play(MediaHit hit) async {
    if (widget.fromSaved) return _startSaved(hit);
    if (widget.inAppVideo && isYoutubeUrl(hit.url)) {
      final started = await togglePreview(
        context,
        hit,
        audioLanguage: context.read<AudioLanguageCubit>().state.selected,
        announceFailure: false,
      );
      if (started || !mounted) return;
    }
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
    final site = youtube ? '' : siteNameOf(hit.url);

    final views = hit.viewCount;
    final uploaded = hit.uploadedAt;
    final rows = <(String, String)>[
      if (!youtube && site.isNotEmpty) (l10n.mediaDetailSite, site),
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
                leading: AppBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // 라이브가 아니면 저장해 둘 수 있다 (유튜브는 영상이라 화질을 고르고, 사운드클라우드 등은 음원만).
                actions: [if (!hit.isLive) _SaveButton(hit: hit)],
              ),
              // 받기 전 상세 화면은 목록 위에 얇은 막대로 읽는 중임을 알린다.
              LoadingBar(loading: state.loading),
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
                        onPlay: () => unawaited(_play(hit)),
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
                              size: AppSizes.iconSm,
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
                    SectionBlock(
                      title: l10n.mediaDetailSectionPreview,
                      children: [
                        Center(child: PreviewButton(hit: hit)),
                        PreviewProgressBar(hitId: hit.id, showTime: true),
                        AudioLanguageRow(
                          onChanged: (id) => _restartPreview(hit, id),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Divider(height: 1, color: p.outline),
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
                    if (rows.isNotEmpty)
                      SectionBlock(
                        title: l10n.mediaDetailSectionInfo,
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: p.outline),
                            _InfoRow(label: rows[i].$1, value: rows[i].$2),
                          ],
                        ],
                      ),
                    if (hit.description.isNotEmpty)
                      SectionBlock(
                        title: l10n.mediaDetailDescription,
                        children: [
                          ExpandableText(
                            hit.description,
                            toggleKey: const ValueKey(
                              'detail-description-toggle',
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              // 저장한 음원 화면에서 연 상세는 재생 조작부를 아래에 늘 고정한다.
              if (widget.fromSaved)
                Builder(
                  builder: (context) {
                    final now = context.watch<NowPlayingCubit>();
                    final current = now.state.track?.id ?? '';
                    // 메인 재생이 임시 저장한 음원을 듣는 중이면 이 곡이 아니어도 같은 조작부를 쓴다.
                    if (current.startsWith(Track.savedIdPrefix)) {
                      return const SavedQueueControls();
                    }
                    return SavedQueueControls(onStart: () => _startSaved(hit));
                  },
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
                        // 이 앱의 주 동작은 받기라서 원본 열기는 보조(tonal)로 둔다.
                        variant: PillVariant.tonal,
                        onPressed: () => _open(hit.url),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PillButton(
                        key: const ValueKey('detail-download'),
                        label: l10n.actionDownload,
                        icon: AppIcons.download,
                        // 실시간 스트리밍은 끝이 없어 받을 수 없다 (버튼을 비활성으로).
                        onPressed: hit.isLive
                            ? null
                            : () => showDownloadDialog(
                                context,
                                title: hit.title,
                                artist: hit.uploader,
                                album: hit.album,
                                duration: hit.duration,
                                thumbnailUrl: hit.thumbnailUrl,
                                url: hit.url,
                                subtitleLangs: hit.subtitleLangs.isEmpty
                                    ? null
                                    : hit.subtitleLangs,
                                autoSubtitleLangs: hit.autoSubtitleLangs,
                                audioLanguage: context
                                    .read<AudioLanguageCubit>()
                                    .state
                                    .selected,
                              ),
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

/// 이 곡을 저장해 두거나 저장을 푼다 (저장하면 임시 저장소가 차도 지워지지 않고 바로 들을 수 있다).
/// 유튜브는 영상이라 저장할 때 화질을 고른다.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SavedVideosCubit>();
    final saved = cubit.contains(hit.id);
    // 목록에는 바로 들어가지만 데이터를 다 받기 전에는 "받는 중"으로 보여, 끝나기 전에 오프라인으로 틀지 않게 한다.
    final downloading =
        saved && cubit.state.any((v) => v.id == hit.id && !v.ready);
    final l10n = context.l10n;
    // 진행률 · 남은 시간은 저장한 음원 목록 줄에만 보인다 (버튼 글자 폭이 흔들리지 않게 "받는 중"만 둔다).
    return PillButton(
      key: const ValueKey('detail-save'),
      label: downloading
          ? l10n.savedVideosDownloading
          : saved
          ? l10n.savedVideosAdded
          : l10n.savedVideosAdd,
      variant: saved && !downloading ? PillVariant.accent : PillVariant.tonal,
      busy: downloading,
      compact: true,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final failed = l10n.savedVideosFailed;
        // 저장된 곡이면 저장한 음원 화면으로 간다 (저장 해제는 거기서).
        if (saved) return unawaited(context.push(savedVideosLocation));
        // 저장한 곡이 정해 둔 용량을 다 채웠으면 새로 저장하지 않는다 (이미 저장한 곡은 그대로 둔다).
        // 이 화면 위에는 용량 상태가 없으므로 그때그때 읽는다 (못 읽으면 한도 0이라 막지 않는다).
        final probe = sl<StreamCacheCubit>();
        await probe.load();
        final cache = probe.state;
        unawaited(probe.close());
        if (!context.mounted) return;
        if (cache.enabled &&
            cache.limitBytes > 0 &&
            cache.savedBytes >= cache.limitBytes) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.savedVideosFull)));
          return;
        }
        VideoQuality? quality;
        if (isYoutubeUrl(hit.url)) {
          final pick = await pickSaveQuality(
            context,
            initial: context.read<VideoQualityCubit>().state,
          );
          if (pick == null) return;
          quality = pick.quality;
        }
        if (!await cubit.add(hit, quality: quality)) {
          messenger.showSnackBar(SnackBar(content: Text(failed)));
        }
      },
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
    // 이 곡을 미리 듣는 중이면 이미지 자리에 소리 없는 영상을 보여 준다 (영상이 아닌 음원은 제외).
    final previewing =
        !audio &&
        hit.url.isNotEmpty &&
        context.select(
          (PreviewCubit c) =>
              c.state.isActive(hit.id) &&
              c.state.status == PreviewStatus.playing,
        );
    final mainVideo = context.select(
      (NowPlayingCubit c) =>
          c.state.track?.id == '${Track.savedIdPrefix}${hit.id}' &&
          c.state.track!.hasVideo,
    );
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
              if (mainVideo)
                // 영상으로 저장한 곡을 메인 재생으로 듣는 중: 네이티브가 소리와 같은 시계로 내는 영상을 그린다.
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: SizedBox(
                    width: width,
                    height: width * 9 / 16,
                    child: const MainVideoWithControls(),
                  ),
                )
              else if (previewing)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: SizedBox(
                    width: width,
                    height: width * 9 / 16,
                    child: _PreviewVideoBox(hit: hit),
                  ),
                )
              else if (!audio)
                // 음원(사운드클라우드 등)은 커버를 가리지 않는다 (원본 열기는 아래 버튼이 한다).
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

/// 미리 듣는 영상 + 재생 컨트롤 (한 번 누르면 컨트롤, 두 번 누르면 10초 이동, 탐색 바, 전체 화면).
class _PreviewVideoBox extends StatelessWidget {
  const _PreviewVideoBox({required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 옵션에서 화질을 바꾸면 그 화질로 영상만 다시 읽어 바꿔 끼운다 (소리는 이어진다).
        ValueListenableBuilder<VideoQuality?>(
          valueListenable: context.read<PreviewCubit>().qualityOverride,
          builder: (context, override, _) => PreviewVideo(
            pageUrl: hit.url,
            quality:
                override ?? context.read<SavedVideosCubit>().qualityOf(hit.id),
            // 소리만 저장한 곡도 상세 화면에서는 오프라인이 아니면 영상을 같이 보여 준다.
            online: true,
          ),
        ),
        const PreviewVideoControls(),
      ],
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

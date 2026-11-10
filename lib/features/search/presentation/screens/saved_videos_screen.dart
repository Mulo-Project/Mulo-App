import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/format/format_bytes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/saved_video.dart';
import '../../domain/entities/video_quality.dart';
import '../bloc/preview_cubit.dart';
import '../bloc/saved_videos_cubit.dart';
import '../bloc/stream_cache_cubit.dart';
import '../widgets/preview_control.dart';
import '../widgets/preview_video.dart';
import '../widgets/preview_video_controls.dart';
import '../widgets/video_quality_sheet.dart';
import 'saved_queue_detail_screen.dart' show showSavedQueueDetail;

/// 저장한 영상 화면 경로 (검색 탭 안).
const savedVideosLocation = '/search/saved';

/// 사용자가 골라 저장해 둔 음원(유튜브는 영상) 목록. 줄을 누르면 상세 화면, 오른쪽 버튼으로 바로 듣고 뺀다.
/// 저장한 영상은 앱 안에 받아 두어 임시 저장소가 차도 지워지지 않는다.
class SavedVideosScreen extends StatefulWidget {
  const SavedVideosScreen({super.key});

  @override
  State<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> {
  @override
  void initState() {
    super.initState();
    // 화면을 열 때 끊겼던 받기를 이어 받는다.
    unawaited(context.read<SavedVideosCubit>().retry());
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<StreamCacheCubit>()..load(),
    // 저장 · 삭제 · 받기 끝남으로 목록이 바뀌면 용량을 다시 읽는다.
    child: BlocListener<SavedVideosCubit, List<SavedVideo>>(
      listener: (context, _) => context.read<StreamCacheCubit>().load(),
      child: Builder(builder: _page),
    ),
  );

  Widget _page(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final videos = context.watch<SavedVideosCubit>().state;
    final preview = context.watch<PreviewCubit>().state;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.savedVideosTitle,
                leading: const AppBackButton(),
                actions: [
                  if (videos.isNotEmpty)
                    PlainButton(
                      key: const ValueKey('saved-clear-all'),
                      label: l10n.savedVideosClearAll,
                      onPressed: () => _confirmClearAll(context),
                    ),
                ],
              ),
              const _StorageLine(),
              if (videos.isNotEmpty) _QueueRow(videos: _ordered(videos)),
              Expanded(
                child: videos.isEmpty
                    ? EmptyState(title: l10n.savedVideosEmpty)
                    : ListView(
                        padding: EdgeInsets.only(
                          bottom:
                              AppSpacing.lg +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          // 음원(낮은 줄)을 위에, 영상(큰 타일)을 아래에 둔다. 구역마다 1번부터 센다.
                          for (final section in [
                            (
                              l10n.savedVideosSectionAudio,
                              [
                                for (final v in videos)
                                  if (v.quality == null) v,
                              ],
                            ),
                            (
                              l10n.savedVideosSectionVideo,
                              [
                                for (final v in videos)
                                  if (v.quality != null) v,
                              ],
                            ),
                          ])
                            if (section.$2.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: SectionTitle(section.$1),
                              ),
                              for (var i = 0; i < section.$2.length; i++)
                                _SavedTile(
                                  number: i + 1,
                                  video: section.$2[i],
                                  active: preview.isActive(section.$2[i].id),
                                ),
                            ],
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

/// 화면에 보이는 순서(음원 먼저, 그 아래 영상)대로 늘어놓은 목록. 재생 목록도 이 순서를 따른다.
List<SavedVideo> _ordered(List<SavedVideo> videos) => [
  for (final v in videos)
    if (v.quality == null) v,
  for (final v in videos)
    if (v.quality != null) v,
];

/// 저장한 음원 화면에서 곡 하나를 틀면 목록 재생으로 시작한다 (그 곡부터, 화면 순서대로).
/// 이미 듣는 곡이면 일시정지 · 이어 듣기만 한다.
Future<void> _playFrom(BuildContext context, SavedVideo video) async {
  final preview = context.read<PreviewCubit>();
  if (preview.state.isActive(video.id)) {
    await preview.togglePause();
    return;
  }
  final nowPlaying = context.read<NowPlayingCubit>();
  // 두 소리가 겹치지 않게 메인 재생은 멈춘다.
  if (nowPlaying.state.isPlaying) nowPlaying.togglePlay();
  final items = [
    for (final v in _ordered(context.read<SavedVideosCubit>().state))
      PreviewQueueItem(v.hit, quality: v.quality),
  ];
  final at = items.indexWhere((i) => i.hit.id == video.id);
  await preview.playQueue(items, start: at < 0 ? 0 : at);
}

/// 전체 재생 · 셔플 · 반복. 누르면 목록 전체를 차례로 듣는다.
class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.videos});

  final List<SavedVideo> videos;

  List<PreviewQueueItem> get _items => [
    for (final v in videos) PreviewQueueItem(v.hit, quality: v.quality),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = context.read<PreviewCubit>();
    final nowPlaying = context.read<NowPlayingCubit>();
    Future<void> start({required bool shuffled}) async {
      // 두 소리가 겹치지 않게 메인 재생은 멈춘다.
      if (nowPlaying.state.isPlaying) nowPlaying.togglePlay();
      final start = shuffled && videos.isNotEmpty
          ? Random().nextInt(videos.length)
          : 0;
      // 목록 화면(지금 곡의 상세 + 조작 줄)을 먼저 열고 틀기 시작한다.
      unawaited(showSavedQueueDetail(context, videos[start].hit));
      await preview.playQueue(_items, start: start, shuffled: shuffled);
    }

    return Padding(
      padding: AppSpacing.screen,
      child: ValueListenableBuilder<bool>(
        valueListenable: preview.loop,
        builder: (context, loop, _) => Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            PillButton(
              key: const ValueKey('saved-play-all'),
              label: l10n.actionPlay,
              icon: AppIcons.play,
              compact: true,
              onPressed: () => start(shuffled: false),
            ),
            PillButton(
              key: const ValueKey('saved-shuffle'),
              label: l10n.actionShuffle,
              icon: AppIcons.shuffle,
              variant: PillVariant.tonal,
              compact: true,
              onPressed: () => start(shuffled: true),
            ),
            PillButton(
              key: const ValueKey('saved-loop'),
              label: l10n.savedVideosLoop,
              icon: AppIcons.repeat,
              variant: PillVariant.tonal,
              selected: loop,
              compact: true,
              onPressed: () => preview.loop.value = !loop,
            ),
            // 목록 재생 중이면 지금 대기열을 연다.
            ValueListenableBuilder<bool>(
              valueListenable: preview.queueActive,
              builder: (context, active, _) => active
                  ? PillButton(
                      key: const ValueKey('saved-queue-open'),
                      label: l10n.savedQueueOpen,
                      icon: AppIcons.queueOutline,
                      variant: PillVariant.tonal,
                      compact: true,
                      onPressed: () {
                        final items = preview.queueItems.value;
                        if (items.isEmpty) return;
                        final pos = preview.queuePos.value.clamp(
                          0,
                          items.length - 1,
                        );
                        unawaited(
                          showSavedQueueDetail(context, items[pos].hit),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 저장한 음원이 쓰는 용량과 기기에 남은 공간 (설정에서만이 아니라 여기서도 보인다).
class _StorageLine extends StatelessWidget {
  const _StorageLine();

  @override
  Widget build(BuildContext context) {
    final info = context.watch<StreamCacheCubit>().state;
    if (info.savedBytes == 0 && info.limitBytes == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          context.l10n.savedVideosStorage(
            formatBytes(info.savedBytes),
            // 남은 공간은 기기 전체가 아니라 정해 둔 임시 저장 공간(한도)에서 쓴 만큼을 뺀 값이다.
            formatBytes(
              (info.limitBytes - info.usedBytes).clamp(0, info.limitBytes),
            ),
          ),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.palette.onSurfaceMuted),
        ),
      ),
    );
  }
}

Future<void> _confirmClearAll(BuildContext context) async {
  final l10n = context.l10n;
  final cubit = context.read<SavedVideosCubit>();
  final ok = await showConfirmDialog(
    context,
    title: l10n.savedVideosClearAllTitle,
    body: l10n.savedVideosClearAllBody,
    confirmLabel: l10n.savedVideosClearAll,
    cancelLabel: l10n.actionCancel,
  );
  if (ok) await cubit.removeAll();
}

/// 저장한 곡 한 줄. 영상(화질을 고른 것)은 위에 16:9 영상 영역, 아래에 번호 · 제목 · 정보 · 버튼을 둔 큰 타일이고,
/// 음원은 번호 · 제목 · 정보 · 버튼만 있는 낮은 줄이다.
class _SavedTile extends StatelessWidget {
  const _SavedTile({
    required this.number,
    required this.video,
    required this.active,
  });

  /// 구역 안의 번호 (1부터).
  final int number;
  final SavedVideo video;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final hit = video.hit;
    final isVideo = video.quality != null;
    // 채널은 한 줄, 화질 · 받는 중 같은 부가 정보는 그 아래 한 줄 (한 줄에 몰면 뒤가 잘린다).
    final percents = context.read<SavedVideosCubit>().progress;
    String extraOf(Map<String, int> pct) => [
      if (isVideo) videoQualityLabel(context, video.quality!),
      if (!video.ready)
        pct[hit.id] == null
            ? l10n.savedVideosDownloading
            : '${l10n.savedVideosDownloading} ${pct[hit.id]}%',
    ].join(' · ');

    final info = InkWell(
      // 정보 부분을 누르면 상세 화면으로 간다 (영상은 위 영역에서 바로 재생).
      onTap: () => showSavedQueueDetail(context, hit),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$number',
                style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (isVideo ? text.bodyLarge : text.bodyMedium)
                        ?.copyWith(color: active ? p.accent : null),
                  ),
                  if (hit.uploader.isNotEmpty)
                    Text(
                      hit.uploader,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ValueListenableBuilder<Map<String, int>>(
                    valueListenable: percents,
                    builder: (_, pct, _) {
                      final extra = extraOf(pct);
                      return extra.isEmpty
                          ? const SizedBox.shrink()
                          : Text(
                              extra,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: p.onSurfaceMuted,
                              ),
                            );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 영상은 재생 버튼이 영상 영역에 있어서 음원만 오른쪽에 둔다.
            if (!isVideo)
              CircleIconButton(
                key: ValueKey('saved-row-play-${hit.id}'),
                icon: active ? AppIcons.pause : AppIcons.play,
                tooltip: l10n.savedVideosPlay,
                size: AppSizes.rowButton,
                onPressed: () => unawaited(_playFrom(context, video)),
              ),
            if (!isVideo) const SizedBox(width: AppSpacing.sm),
            CircleIconButton(
              icon: AppIcons.delete,
              tooltip: l10n.savedVideosRemove,
              size: AppSizes.rowButton,
              onPressed: () =>
                  context.read<SavedVideosCubit>().remove(video.id),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        isVideo ? AppSpacing.md : 0,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isVideo) _VideoArea(video: video, active: active),
          info,
        ],
      ),
    );
  }
}

/// 타일 위의 16:9 영상 영역: 평소엔 썸네일 + 재생 버튼, 재생하면 그 자리에서 영상이 나오고
/// 한 번 누르면 컨트롤(탐색 · 10초 이동 · 전체 화면)이 뜬다.
class _VideoArea extends StatelessWidget {
  const _VideoArea({required this.video, required this.active});

  final SavedVideo video;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final hit = video.hit;
    final status = context.select((PreviewCubit c) => c.state.status);
    final playing = active && status == PreviewStatus.playing;
    final loading = active && status == PreviewStatus.loading;
    final thumb = hit.thumbnailUrl;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        return SizedBox(
          width: width,
          height: width * 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ArtworkBox(
                  image: thumb == null ? null : NetworkImage(thumb),
                  size: width * 9 / 16,
                  width: width,
                  radius: 0,
                  tone: toneFor(hit.id),
                ),
                if (playing) ...[
                  ValueListenableBuilder<VideoQuality?>(
                    valueListenable: context
                        .read<PreviewCubit>()
                        .qualityOverride,
                    builder: (context, override, _) => PreviewVideo(
                      pageUrl: hit.url,
                      quality: override ?? video.quality,
                    ),
                  ),
                  const PreviewVideoControls(),
                ] else if (loading)
                  Center(
                    child: PreviewLoadingRing(
                      state: context.read<PreviewCubit>().state,
                      size: AppSizes.circleButton,
                    ),
                  )
                else
                  Center(
                    child: CircleIconButton(
                      key: ValueKey('saved-play-${hit.id}'),
                      icon: AppIcons.play,
                      tooltip: context.l10n.savedVideosPlay,
                      emphasized: true,
                      size: AppSizes.circleButtonLarge,
                      onPressed: () => unawaited(_playFrom(context, video)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

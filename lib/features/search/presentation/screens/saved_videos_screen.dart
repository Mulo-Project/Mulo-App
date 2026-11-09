import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/saved_video.dart';
import '../../domain/entities/video_quality.dart';
import '../bloc/preview_cubit.dart';
import '../bloc/saved_videos_cubit.dart';
import '../widgets/preview_control.dart';
import '../widgets/preview_video.dart';
import '../widgets/preview_video_controls.dart';
import '../widgets/video_quality_sheet.dart';
import 'media_detail_screen.dart';

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
  Widget build(BuildContext context) {
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
                              [for (final v in videos) if (v.quality == null) v],
                            ),
                            (
                              l10n.savedVideosSectionVideo,
                              [for (final v in videos) if (v.quality != null) v],
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
    final sub = [
      if (hit.uploader.isNotEmpty) hit.uploader,
      if (isVideo) videoQualityLabel(context, video.quality!),
      if (!video.ready) l10n.savedVideosDownloading,
    ].join(' · ');

    final info = InkWell(
      // 정보 부분을 누르면 상세 화면으로 간다 (영상은 위 영역에서 바로 재생).
      onTap: () => showMediaDetail(context, hit),
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
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 영상은 재생 버튼이 영상 영역에 있어서 음원만 오른쪽에 둔다.
            if (!isVideo)
              CircleIconButton(
                icon: active ? AppIcons.pause : AppIcons.play,
                tooltip: l10n.savedVideosPlay,
                size: AppSizes.rowButton,
                onPressed: () => togglePreview(context, hit),
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
                    valueListenable: context.read<PreviewCubit>().qualityOverride,
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
                      onPressed: () => togglePreview(context, hit),
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

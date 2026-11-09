import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/saved_video.dart';
import '../bloc/preview_cubit.dart';
import '../bloc/saved_videos_cubit.dart';
import '../widgets/preview_control.dart';
import '../widgets/video_quality_sheet.dart';
import 'media_detail_screen.dart';

/// 저장한 영상 화면 경로 (검색 탭 안).
const savedVideosLocation = '/search/saved';

/// 사용자가 골라 저장해 둔 음원(유튜브는 영상) 목록. 줄을 누르면 상세 화면, 오른쪽 버튼으로 바로 듣고 뺀다.
/// 저장한 영상은 앱 안에 받아 두어 임시 저장소가 차도 지워지지 않는다.
class SavedVideosScreen extends StatelessWidget {
  const SavedVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
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
              ),
              Expanded(
                child: videos.isEmpty
                    ? Padding(
                        padding: AppSpacing.screen,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            l10n.savedVideosEmpty,
                            style: text.bodySmall,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          bottom:
                              AppSpacing.lg +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: videos.length,
                        itemBuilder: (context, i) => _SavedTile(
                          video: videos[i],
                          active: preview.isActive(videos[i].id),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.video, required this.active});

  final SavedVideo video;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final hit = video.hit;
    final sub = [
      if (hit.uploader.isNotEmpty) hit.uploader,
      if (video.quality != null) videoQualityLabel(context, video.quality!),
      if (!video.ready) l10n.savedVideosDownloading,
    ].join(' · ');

    return InkWell(
      // 줄을 누르면 상세 화면으로 간다 (듣기 · 영상 보기는 거기서도, 오른쪽 버튼으로도 된다).
      onTap: () => showMediaDetail(context, hit),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: active ? p.accent : null,
                    ),
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
            CircleIconButton(
              icon: active ? AppIcons.pause : AppIcons.play,
              tooltip: l10n.savedVideosPlay,
              size: AppSizes.rowButton,
              onPressed: () => togglePreview(context, hit),
            ),
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
  }
}

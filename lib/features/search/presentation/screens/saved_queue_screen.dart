import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/cached_web_image.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/screens/queue_screen.dart'
    show QueueHeader;
import '../bloc/preview_cubit.dart';

/// 저장한 음원 대기열 경로 (저장한 음원 화면 안).
const savedQueueLocation = '/search/saved/queue';

/// 저장한 음원 재생 목록 화면. 메인 재생 대기열 화면과 같은 모양으로, 곡을 누르면 그 곡부터 듣고
/// 길게 눌러 끌면 순서가 바뀌고 오른쪽 버튼으로 뺀다.
class SavedQueueScreen extends StatelessWidget {
  const SavedQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final preview = context.read<PreviewCubit>();
    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.savedQueueTitle,
                leading: const AppBackButton(),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    preview.queueItems,
                    preview.queuePos,
                    preview.shuffle,
                    preview.repeatListenable,
                  ]),
                  builder: (context, _) {
                    final items = preview.queueItems.value;
                    final pos = preview.queuePos.value;
                    if (items.isEmpty) {
                      return EmptyState(title: l10n.playerQueueEmpty);
                    }
                    final playing = context.select(
                      (PreviewCubit c) =>
                          c.state.status == PreviewStatus.playing &&
                          !c.state.paused,
                    );
                    return Column(
                      children: [
                        QueueHeader(
                          count: items.length,
                          shuffle: preview.shuffle.value,
                          onShuffle: preview.toggleShuffle,
                          repeat: preview.repeatMode,
                          onRepeat: preview.cycleRepeat,
                          onClear: () {
                            preview.stop();
                            Navigator.of(context).maybePop();
                          },
                          showSelect: false,
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: EdgeInsets.only(
                              bottom:
                                  AppSpacing.lg +
                                  MediaQuery.paddingOf(context).bottom,
                            ),
                            buildDefaultDragHandles: false,
                            proxyDecorator: (child, _, _) => Material(
                              color: p.surfaceHigh,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              elevation: 0,
                              child: child,
                            ),
                            itemCount: items.length,
                            onReorderItem: preview.moveInQueue,
                            itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
                              key: ValueKey(items[i].hit.id),
                              index: i,
                              child: _Tile(
                                item: items[i],
                                number: i + 1,
                                active: i == pos,
                                playing: playing,
                                onTap: () => preview.jumpTo(i),
                                onRemove: () => preview.removeFromQueue(i),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.number,
    required this.active,
    required this.playing,
    required this.onTap,
    required this.onRemove,
  });

  final PreviewQueueItem item;
  final int number;
  final bool active;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hit = item.hit;
    final thumb = hit.thumbnailUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? p.accent.withValues(alpha: .14) : null,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: TrackTile(
          title: hit.title,
          subtitle: hit.uploader.isEmpty
              ? context.l10n.unknownArtist
              : hit.uploader,
          tone: toneFor(hit.id),
          artwork: thumb == null ? null : CachedWebImage(thumb),
          active: active,
          number: number,
          horizontalPadding: AppSpacing.xs,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    playing ? AppIcons.equalizer : AppIcons.pause,
                    size: AppSizes.iconSm,
                    color: p.accent,
                  ),
                ),
              RowIconButton(
                icon: AppIcons.close,
                tooltip: context.l10n.savedVideosRemove,
                onPressed: onRemove,
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

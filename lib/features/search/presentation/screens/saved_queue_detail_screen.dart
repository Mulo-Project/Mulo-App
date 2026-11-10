import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/preview_cubit.dart';
import 'media_detail_screen.dart';
import 'saved_queue_screen.dart' show savedQueueLocation;

/// 저장한 음원 재생 목록을 듣는 동안 보는 화면: 지금 곡의 상세 화면에 아래 목록 조작 줄을 붙인다.
/// 곡이 넘어가면 화면도 다음 곡의 상세 화면으로 바뀐다.
Future<void> showSavedQueueDetail(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'saved-queue-detail'),
      builder: (_) => const SavedQueueDetailScreen(),
    ),
  );
}

class SavedQueueDetailScreen extends StatefulWidget {
  const SavedQueueDetailScreen({super.key});

  @override
  State<SavedQueueDetailScreen> createState() => _SavedQueueDetailScreenState();
}

class _SavedQueueDetailScreenState extends State<SavedQueueDetailScreen> {
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    final preview = context.read<PreviewCubit>();
    final p = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([preview.queueItems, preview.queuePos]),
      builder: (context, _) {
        final items = preview.queueItems.value;
        final pos = preview.queuePos.value;
        if (items.isEmpty) {
          // 목록이 끝났거나 멈췄다: 이 화면을 닫는다.
          if (!_closing) {
            _closing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).maybePop();
            });
          }
          return Scaffold(backgroundColor: p.background);
        }
        final hit = items[pos.clamp(0, items.length - 1)].hit;
        return Scaffold(
          backgroundColor: p.background,
          body: Column(
            children: [
              Expanded(
                // 아래 조작 줄이 하단 안전 영역을 쓰므로 상세 화면은 아래 여백을 뺀다.
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: MediaDetailScreen(key: ValueKey(hit.id), hit: hit),
                ),
              ),
              const _QueueControls(),
            ],
          ),
        );
      },
    );
  }
}

/// 상세 화면 아래의 재생 목록 조작: 셔플 · 이전 · 재생/멈춤 · 다음 · 반복 · 대기열.
class _QueueControls extends StatelessWidget {
  const _QueueControls();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final preview = context.read<PreviewCubit>();
    final paused = context.select((PreviewCubit c) => c.state.paused);
    final loading = context.select(
      (PreviewCubit c) => c.state.status == PreviewStatus.loading,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([preview.shuffle, preview.loop]),
            builder: (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RowIconButton(
                  key: const ValueKey('queue-bar-shuffle'),
                  icon: AppIcons.shuffle,
                  tooltip: preview.shuffle.value
                      ? l10n.shuffleOff
                      : l10n.shuffleOn,
                  accent: preview.shuffle.value,
                  onPressed: preview.toggleShuffle,
                ),
                RowIconButton(
                  key: const ValueKey('queue-bar-previous'),
                  icon: AppIcons.skipPrevious,
                  tooltip: l10n.actionPrevious,
                  onPressed: preview.previous,
                ),
                CircleIconButton(
                  key: const ValueKey('queue-bar-play'),
                  icon: paused ? AppIcons.play : AppIcons.pause,
                  tooltip: paused
                      ? l10n.searchPreviewResume
                      : l10n.searchPreviewPause,
                  emphasized: true,
                  onPressed: loading ? null : preview.togglePause,
                ),
                RowIconButton(
                  key: const ValueKey('queue-bar-next'),
                  icon: AppIcons.skipNext,
                  tooltip: l10n.actionNext,
                  onPressed: preview.next,
                ),
                RowIconButton(
                  key: const ValueKey('queue-bar-loop'),
                  icon: AppIcons.repeat,
                  tooltip: l10n.playerRepeat,
                  accent: preview.loop.value,
                  onPressed: () => preview.loop.value = !preview.loop.value,
                ),
                RowIconButton(
                  key: const ValueKey('queue-bar-queue'),
                  icon: AppIcons.queueOutline,
                  tooltip: l10n.savedQueueOpen,
                  onPressed: () => context.push(savedQueueLocation),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

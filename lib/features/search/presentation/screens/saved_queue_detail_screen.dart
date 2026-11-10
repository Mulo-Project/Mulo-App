import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/widgets/player_seek.dart';
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

  /// 목록이 한 번이라도 채워진 적이 있다 (열자마자 비어 있는 건 곧 채워질 것이라 닫지 않는다).
  bool _seen = false;

  @override
  Widget build(BuildContext context) {
    final preview = context.read<PreviewCubit>();
    final p = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([preview.queueItems, preview.queuePos]),
      builder: (context, _) {
        final items = preview.queueItems.value;
        final pos = preview.queuePos.value;
        if (items.isNotEmpty) _seen = true;
        if (items.isEmpty) {
          // 목록이 끝났거나 멈췄다: 이 화면을 닫는다.
          if (_seen && !_closing) {
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

/// 상세 화면 아래의 재생 조작: 메인 플레이어와 같은 순서로 진행 막대 → 10초 · 이전 · 재생 · 다음 · 10초
/// → 셔플 · 반복 · 대기열. 높이는 화면의 3분의 1을 넘지 않는다.
class _QueueControls extends StatefulWidget {
  const _QueueControls();

  @override
  State<_QueueControls> createState() => _QueueControlsState();
}

class _QueueControlsState extends State<_QueueControls> {
  /// 끌고 있는 동안의 위치 비율 (놓을 때 한 번만 실제로 옮긴다).
  double? _scrub;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cap = MediaQuery.sizeOf(context).height / 3;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.outline)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: cap),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: _content(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final preview = context.read<PreviewCubit>();
    final (paused, loading, fraction, position, total) = context.select(
      (PreviewCubit c) => (
        c.state.paused,
        c.state.status == PreviewStatus.loading,
        c.state.fraction,
        c.state.progress?.position ?? Duration.zero,
        c.state.progress?.duration ?? Duration.zero,
      ),
    );
    final shown = _scrub ?? fraction;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerSeekBar(
            key: const ValueKey('queue-bar-seek'),
            progress: shown,
            position: _scrub == null || total == Duration.zero
                ? position
                : total * _scrub!,
            total: total,
            onSeek: (v) => setState(() => _scrub = v.clamp(0.0, 1.0)),
            onSeekEnd: () {
              final v = _scrub;
              setState(() => _scrub = null);
              if (v != null) preview.seekTo(v);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                key: const ValueKey('queue-bar-back10'),
                icon: AppIcons.replay10,
                tooltip: l10n.playerRewind10,
                onPressed: () => preview.seekBy(const Duration(seconds: -10)),
              ),
              CircleIconButton(
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
                size: AppSizes.circleButtonLarge,
                onPressed: loading ? null : preview.togglePause,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-next'),
                icon: AppIcons.skipNext,
                tooltip: l10n.actionNext,
                onPressed: preview.next,
              ),
              CircleIconButton(
                key: const ValueKey('queue-bar-forward10'),
                icon: AppIcons.forward10,
                tooltip: l10n.playerForward10,
                onPressed: () => preview.seekBy(const Duration(seconds: 10)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ListenableBuilder(
            listenable: Listenable.merge([preview.shuffle, preview.loop]),
            builder: (context, _) => Row(
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
                  key: const ValueKey('queue-bar-loop'),
                  icon: AppIcons.repeat,
                  tooltip: l10n.playerRepeat,
                  accent: preview.loop.value,
                  onPressed: () => preview.loop.value = !preview.loop.value,
                ),
                const Spacer(),
                RowIconButton(
                  key: const ValueKey('queue-bar-queue'),
                  icon: AppIcons.queueOutline,
                  tooltip: l10n.savedQueueOpen,
                  onPressed: () => context.push(savedQueueLocation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/lyrics_sync_cubit.dart';

// 가사 싱크 화면의 줄 · 조작 막대 · 시계 (lyrics_sync_screen에서 나눔).

class SyncLineRow extends StatelessWidget {
  const SyncLineRow({
    super.key,
    required this.index,
    required this.draft,
    required this.selected,
    this.inRange = false,
    this.afterFocus = false,
    required this.canMerge,
    required this.clock,
    required this.onTap,
    this.onLongPress,
  });

  final int index;
  final SyncDraft draft;
  final bool selected;
  final bool inRange;
  final bool afterFocus;
  final bool canMerge;
  final String Function(Duration) clock;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final time = draft.times[index];
    final isCurrent = index == draft.current;
    final color = isCurrent
        ? p.accent
        : (time == null ? p.onSurfaceMuted : p.onSurface);
    final sync = context.read<LyricsSyncCubit>();
    // 이어서 새로 찍을 수 있는 맨 앞 빈 칸은 눌러서 돌아오기 쉽게 항상 표시한다.
    final isFrontier = draft.stamped > 0 && index == draft.times.indexOf(null);
    // 포커스한 싱크 바로 다음 칸의 기존 싱크 시간을 재생이 이미 지나갔는가.
    final passed =
        afterFocus &&
        time != null &&
        context.select<NowPlayingCubit, bool>((c) => c.state.position > time);

    final block = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            // 다음에 찍을 줄은 왼쪽에 강조 선을 둔다.
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isCurrent ? p.accent : p.accent.withValues(alpha: 0),
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    time != null
                        ? clock(time)
                        : (isFrontier ? l10n.lyricsSyncNextSlot : '--:--.--'),
                    style: text.labelMedium?.copyWith(
                      // 찍은 줄(완료)과 다음에 찍을 줄은 강조 색, 아직인 줄은 흐리게.
                      color: time != null || isCurrent || isFrontier
                          ? p.accent
                          : p.onSurfaceMuted,
                      decoration: passed ? TextDecoration.lineThrough : null,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    style: (isCurrent ? text.bodyLarge : text.bodyMedium)!
                        .copyWith(color: color),
                    child: Text(draft.texts[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 건너뛰어 같은 시간으로 묶인 칸은 따로 표시하고, 다시 나눌 수 있게 한다.
        if (canMerge && sync.isMerged(index))
          Padding(
            padding: const EdgeInsets.only(left: 76 + AppSpacing.sm + 3),
            child: Row(
              children: [
                Text(
                  l10n.lyricsSyncMerged(draft.sizes[index]),
                  style: text.labelSmall?.copyWith(color: p.accent),
                ),
                PlainButton(
                  label: l10n.lyricsSyncUnmerge,
                  onPressed: () => sync.split(index),
                ),
              ],
            ),
          ),
        if (selected && time != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 위: 시간 맞추기 버튼
                Wrap(
                  children: [
                    for (final ms in const [-500, -100, -10, 10, 100, 500])
                      PlainButton(
                        label: '${ms > 0 ? '+' : '−'}${ms.abs() / 1000}s',
                        onPressed: () {
                          sync.nudge(Duration(milliseconds: ms));
                          // 조정한 시간으로 재생도 옮겨, 바로 들어 보며 맞춘다.
                          final moved = sync.state.draft.times[index];
                          if (moved != null) {
                            context.read<NowPlayingCubit>().seekTo(moved);
                          }
                        },
                      ),
                  ],
                ),
                // 뒤에 찍은 싱크가 더 있으면 이 싱크로 되돌리는 취소.
                if (draft.times.skip(index + 1).any((t) => t != null))
                  Align(
                    alignment: Alignment.centerRight,
                    child: PlainButton(
                      icon: AppIcons.undo,
                      label: l10n.lyricsSyncCancelAfter,
                      tooltip: l10n.lyricsSyncCancelAfterHint,
                      onPressed: () => sync.rewindTo(index),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
    // 포커스된 싱크 칸(시간 조정 버튼까지)은 영역 전체에 색을 깐다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: selected || inRange
                ? p.accent.withValues(alpha: inRange ? .22 : .16)
                : null,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: block,
        ),
        // 싱크 칸 사이를 구분하는 가는 선.
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          color: p.outline,
        ),
      ],
    );
  }
}

class SyncControlBar extends StatelessWidget {
  const SyncControlBar({
    super.key,
    required this.stepMs,
    required this.autoPause,
    required this.onAutoPause,
    required this.onNow,
    required this.onUndo,
    required this.onPrevious,
    required this.onSkip,
    required this.onSeek,
    required this.onPickStep,
  });

  final int stepMs;
  final bool autoPause;
  final VoidCallback onAutoPause;
  final VoidCallback onNow;
  final VoidCallback onUndo;
  final VoidCallback onPrevious;
  final void Function(int sign) onSkip;
  final ValueChanged<double> onSeek;
  final void Function(BuildContext buttonContext) onPickStep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final np = context.watch<NowPlayingCubit>();
    final sync = context.watch<LyricsSyncCubit>();
    final draft = sync.state.draft;
    final total = np.state.track?.duration ?? Duration.zero;
    final totalMs = total.inMilliseconds;
    // 찍어 둔 줄마다 슬라이더 위에 작은 표시를 남긴다.
    final marks = totalMs == 0
        ? const <double>[]
        : [
            for (final t in draft.times)
              if (t != null) t.inMilliseconds / totalMs,
          ];
    // 지금 포커스된 줄의 표시는 따로 강조한다.
    final at = sync.state.selected;
    final focus = totalMs == 0 || at == null || draft.times[at] == null
        ? null
        : draft.times[at]!.inMilliseconds / totalMs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Builder(
                builder: (buttonContext) => PlainButton(
                  label: '−${syncStepLabel(stepMs)}',
                  tooltip: l10n.lyricsSyncBackBy(stepMs / 1000),
                  onPressed: () => onSkip(-1),
                  onLongPress: () => onPickStep(buttonContext),
                ),
              ),
              Expanded(
                child: AppSlider(
                  semanticLabel: l10n.lyricsSyncSeek,
                  value: totalMs == 0
                      ? 0
                      : np.state.position.inMilliseconds / totalMs,
                  marks: marks,
                  activeMark: focus,
                  thumbAlpha: .5,
                  onChanged: totalMs == 0 ? null : onSeek,
                ),
              ),
              Builder(
                builder: (buttonContext) => PlainButton(
                  label: '+${syncStepLabel(stepMs)}',
                  tooltip: l10n.lyricsSyncForwardBy(stepMs / 1000),
                  onPressed: () => onSkip(1),
                  onLongPress: () => onPickStep(buttonContext),
                ),
              ),
            ],
          ),
          const Align(alignment: Alignment.centerRight, child: SyncClockText()),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              CircleIconButton(
                icon: AppIcons.undo,
                tooltip: l10n.lyricsSyncUndo,
                onPressed: draft.canUndo ? onUndo : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: AppIcons.skipPrevious,
                tooltip: l10n.lyricsSyncPrevious,
                onPressed: draft.stamped > 0 ? onPrevious : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: np.state.isPlaying ? AppIcons.pause : AppIcons.play,
                tooltip: np.state.isPlaying
                    ? l10n.lyricsSyncPause
                    : l10n.lyricsSyncPlay,
                emphasized: true,
                onPressed: np.togglePlay,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PillButton(
                    label: l10n.lyricsSyncNow,
                    icon: AppIcons.touch,
                    onPressed: draft.current >= draft.length ? null : onNow,
                  ),
                ),
              ),
            ],
          ),
          // 버튼 줄 아래 한 줄을 더 써서 자동 멈춤을 글자로 보여 준다 (버튼 크기는 그대로).
          Align(
            alignment: Alignment.centerLeft,
            child: PlainButton(
              icon: AppIcons.timer,
              label: l10n.lyricsSyncAutoPause,
              tooltip: l10n.lyricsSyncAutoPauseHint,
              accent: autoPause,
              onPressed: onAutoPause,
            ),
          ),
        ],
      ),
    );
  }
}

/// 지금 재생 위치 / 곡 전체 시간. 몇 줄 남았는지 보이는 위쪽에 둔다.
class SyncClockText extends StatelessWidget {
  const SyncClockText({super.key});

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NowPlayingCubit>();
    return Text(
      '${formatDuration(np.state.position)} / '
      '${formatDuration(np.state.track?.duration ?? Duration.zero)}',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.palette.onSurfaceMuted,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// 이동 단위 글자: 1초 미만은 0.1s처럼, 1분 단위는 1m, 나머지는 정수 초.
String syncStepLabel(int ms) {
  if (ms < 1000) return '${ms / 1000}s';
  if (ms >= 60000 && ms % 60000 == 0) return '${ms ~/ 60000}m';
  return '${ms ~/ 1000}s';
}

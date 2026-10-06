import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/preview_progress.dart';
import '../bloc/preview_cubit.dart';
import '../screens/media_detail_screen.dart';

/// [hit] 미리 듣기를 시작하거나(이미 듣는 중이면) 멈춘다.
/// 소리가 나기 시작하면 메인 재생은 멈추고, 시작하지 못하면 안내를 띄운다.
Future<void> togglePreview(BuildContext context, MediaHit hit) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final preview = context.read<PreviewCubit>();
  final nowPlaying = context.read<NowPlayingCubit>();

  final failure = await preview.toggle(hit);
  if (failure != null) {
    // 까닭을 알 수 있게 엔진이 알려 준 마지막 줄을 덧붙인다.
    final detail = preview.lastFailureDetail
        .split('\n')
        .map((l) => l.trim())
        .lastWhere((l) => l.isNotEmpty, orElse: () => '');
    final message = switch (failure) {
      EngineFailure.unavailable => l10n.searchPreviewUnavailable,
      EngineFailure.network => l10n.searchNetworkBody,
      EngineFailure.notFound => l10n.searchNotFoundBody,
      _ => l10n.searchPreviewFailed,
    };
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          detail.isEmpty || failure == EngineFailure.unavailable
              ? message
              : '$message\n${detail.length > 400 ? detail.substring(0, 400) : detail}',
        ),
      ),
    );
    return;
  }
  // 두 소리가 겹치지 않게 메인 재생은 미리 듣기가 시작될 때 멈춘다.
  final state = preview.state;
  if (state.isActive(hit.id) &&
      state.status == PreviewStatus.playing &&
      nowPlaying.state.isPlaying) {
    nowPlaying.togglePlay();
  }
}

/// 상세 화면의 미리 듣기 버튼. 준비 중이거나 듣는 중이면 누를 때 멈춘다.
class PreviewButton extends StatelessWidget {
  const PreviewButton({super.key, required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = context.select(
      (PreviewCubit c) =>
          c.state.isActive(hit.id) ? c.state.status : PreviewStatus.idle,
    );
    return PillButton(
      label: switch (status) {
        PreviewStatus.idle => l10n.searchPreview,
        PreviewStatus.loading => l10n.searchPreviewLoading,
        PreviewStatus.playing => l10n.searchPreviewStop,
      },
      icon: switch (status) {
        PreviewStatus.idle => AppIcons.headphones,
        PreviewStatus.loading => AppIcons.hourglassTop,
        PreviewStatus.playing => AppIcons.pause,
      },
      variant: PillVariant.tonal,
      busy: status == PreviewStatus.loading,
      onPressed: () => togglePreview(context, hit),
    );
  }
}

/// 검색 결과 줄 오른쪽의 미리 듣기 버튼 (면 없는 작은 아이콘 버튼).
/// 누르면 미리 듣고, 준비 중이거나 듣는 중이면 강조 색으로 바뀌어 누를 때 멈춘다.
class PreviewRowButton extends StatelessWidget {
  const PreviewRowButton({super.key, required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.select(
      (PreviewCubit c) => c.state.isActive(hit.id) ? c.state : null,
    );
    final status = state?.status ?? PreviewStatus.idle;
    return RowIconButton(
      key: const ValueKey('preview-row-button'),
      icon: switch (status) {
        PreviewStatus.idle => AppIcons.headphones,
        PreviewStatus.loading => AppIcons.hourglassTop,
        PreviewStatus.playing => AppIcons.pause,
      },
      tooltip: switch (status) {
        PreviewStatus.idle => l10n.searchPreview,
        PreviewStatus.loading => l10n.searchPreviewLoading,
        PreviewStatus.playing => l10n.searchPreviewStop,
      },
      accent: status != PreviewStatus.idle,
      busy: status == PreviewStatus.loading,
      busyChild: state == null ? null : PreviewLoadingRing(state: state),
      onPressed: () => togglePreview(context, hit),
    );
  }
}

/// 소리가 나기까지 남은 시간을 보여 주는 작은 원: 호가 차오르고 가운데에 남은 초가 있다.
/// 어림한 시간이 지나도 시작하지 않으면 마지막 1초에서 기다린다.
class PreviewLoadingRing extends StatelessWidget {
  const PreviewLoadingRing({super.key, required this.state, this.size = 28});

  final PreviewState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final started = state.loadStartedAt;
    final total = state.expectedLoad;
    if (started == null || total <= Duration.zero) {
      return SizedBox.square(dimension: size);
    }
    final elapsed = DateTime.now().difference(started);
    final begin = (elapsed.inMilliseconds / total.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final text = Theme.of(context).textTheme.labelSmall;
    return TweenAnimationBuilder<double>(
      key: ValueKey(started),
      tween: Tween(begin: begin, end: 1),
      duration: total * (1 - begin),
      builder: (context, v, _) {
        final left = (total.inSeconds * (1 - v)).ceil().clamp(1, 99);
        return CountdownRing(
          key: const ValueKey('preview-loading-ring'),
          value: v,
          size: size,
          child: Text('$left', style: text?.copyWith(fontSize: 10)),
        );
      },
    );
  }
}

/// 다른 화면에서도 보이는 미리 듣기 줄: 제목 · 진행 막대 · 시간 · 멈춤 버튼.
/// 미리 듣기가 없으면 아무것도 그리지 않는다.
class PreviewMiniBar extends StatelessWidget {
  const PreviewMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PreviewCubit>().state;
    if (state.status == PreviewStatus.idle) return const SizedBox.shrink();
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final loading = state.status == PreviewStatus.loading;
    final progress = state.progress;
    final hit = state.hit;
    return Padding(
      key: const ValueKey('preview-mini-bar'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(AppIcons.headphones, size: 18, color: p.accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목을 누르면 이 곡의 상세 화면(유튜브 정보)을 연다.
                GestureDetector(
                  key: const ValueKey('preview-mini-open'),
                  behavior: HitTestBehavior.opaque,
                  onTap: hit == null
                      ? null
                      : () => showMediaDetail(context, hit),
                  child: Text(
                    state.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                loading
                    ? const ProgressLine(value: 0, height: 3)
                    : PreviewSeekLine(fraction: state.fraction, height: 3),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (loading)
            PreviewLoadingRing(state: state, size: 24)
          else
            Text(
              _timeText(progress),
              style: text.labelSmall?.copyWith(color: p.onSurfaceMuted),
            ),
          RowIconButton(
            icon: AppIcons.close,
            tooltip: l10n.searchPreviewStop,
            onPressed: () => context.read<PreviewCubit>().stop(),
          ),
        ],
      ),
    );
  }
}

String _timeText(PreviewProgress? progress) {
  final d = progress?.duration;
  return '${formatDuration(progress?.position ?? Duration.zero)}'
      ' / ${d == null ? '--:--' : formatDuration(d)}';
}

/// 눌러서 · 끌어서 옮길 수 있는 미리 듣기 진행 막대.
/// 끌고 있는 동안은 손가락 자리를 보여 주고, 손을 뗄 때 한 번만 실제로 옮긴다.
/// 길이를 아직 모르면 옮기지 않는다.
class PreviewSeekLine extends StatefulWidget {
  const PreviewSeekLine({super.key, required this.fraction, this.height = 4});

  final double fraction;
  final double height;

  @override
  State<PreviewSeekLine> createState() => _PreviewSeekLineState();
}

class _PreviewSeekLineState extends State<PreviewSeekLine> {
  double? _drag;

  double _at(double dx, double width) =>
      width <= 0 ? 0 : (dx / width).clamp(0.0, 1.0);

  void _commit() {
    final v = _drag;
    setState(() => _drag = null);
    if (v != null) context.read<PreviewCubit>().seekTo(v);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return GestureDetector(
          key: const ValueKey('preview-seek'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => setState(() => _drag = _at(d.localPosition.dx, w)),
          onTapUp: (_) => _commit(),
          onTapCancel: () => setState(() => _drag = null),
          onHorizontalDragStart: (d) =>
              setState(() => _drag = _at(d.localPosition.dx, w)),
          onHorizontalDragUpdate: (d) =>
              setState(() => _drag = _at(d.localPosition.dx, w)),
          onHorizontalDragEnd: (_) => _commit(),
          onHorizontalDragCancel: () => setState(() => _drag = null),
          // 누를 자리를 넉넉히 (막대는 얇아서).
          child: SizedBox(
            height: widget.height + 16,
            child: Center(
              child: ProgressLine(
                value: _drag ?? widget.fraction,
                height: widget.height,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 미리 듣는 곡의 재생 진행도: 얼마나 들었는지 막대 + 시간.
/// 이 곡을 듣고 있지 않으면 아무것도 그리지 않는다. [showTime]이면 막대 아래에 시간도 보인다.
class PreviewProgressBar extends StatelessWidget {
  const PreviewProgressBar({
    super.key,
    required this.hitId,
    this.showTime = false,
  });

  final String hitId;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final state = context.select(
      (PreviewCubit c) => c.state.isActive(hitId) ? c.state : null,
    );
    if (state == null || state.status != PreviewStatus.playing) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme.bodySmall;
    final progress = state.progress;
    final duration = progress?.duration;
    final bar = Column(
      key: const ValueKey('preview-progress'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PreviewSeekLine(fraction: state.fraction),
        if (showTime) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(progress?.position ?? Duration.zero),
                key: const ValueKey('preview-position'),
                style: text,
              ),
              Text(
                duration == null ? '--:--' : formatDuration(duration),
                key: const ValueKey('preview-duration'),
                style: text,
              ),
            ],
          ),
        ],
      ],
    );
    return showTime
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
              0,
            ),
            child: bar,
          )
        : bar;
  }
}

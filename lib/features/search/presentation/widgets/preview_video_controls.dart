import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../../player/presentation/widgets/fullscreen_video.dart';
import '../bloc/preview_cubit.dart';
import 'preview_control.dart';

/// 미리 듣는 영상 위에 얹는 재생 컨트롤 (유튜브처럼): 화면을 한 번 누르면 컨트롤이 뜨고 몇 초 뒤 사라진다.
/// 가운데 10초 뒤로 · 재생/일시정지 · 10초 앞으로, 아래에 진행 막대 · 시간 · 전체 화면.
/// 화면 왼쪽 · 오른쪽 절반을 두 번 누르면 10초 뒤로 · 앞으로. 멈춰 있는 동안에는 계속 보인다.
/// [fullscreen]이면 이미 전체 화면이라 전체 화면 버튼은 없다.
class PreviewVideoControls extends StatefulWidget {
  const PreviewVideoControls({super.key, this.fullscreen = false});

  final bool fullscreen;

  @override
  State<PreviewVideoControls> createState() => _PreviewVideoControlsState();
}

class _PreviewVideoControlsState extends State<PreviewVideoControls> {
  static const _hideAfter = Duration(seconds: 3);
  static const _step = Duration(seconds: 10);
  var _shown = false;
  Timer? _timer;

  void _reveal() {
    setState(() => _shown = true);
    _timer?.cancel();
    _timer = Timer(_hideAfter, () {
      if (mounted) setState(() => _shown = false);
    });
  }

  void _toggle() {
    if (_shown) {
      _timer?.cancel();
      setState(() => _shown = false);
    } else {
      _reveal();
    }
  }

  void _skip(Duration delta) {
    context.read<PreviewCubit>().seekBy(delta);
    _reveal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.palette.onSurface,
    );
    final state = context.select((PreviewCubit c) => c.state);
    final paused = state.paused;
    final show = paused || _shown;
    final progress = state.progress;
    final duration = progress?.duration;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 누르면 컨트롤 보이기 · 숨기기, 두 번 누르면 그쪽으로 10초 이동.
        Row(
          children: [
            for (final back in [true, false])
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggle,
                  onDoubleTap: () => _skip(back ? -_step : _step),
                ),
              ),
          ],
        ),
        IgnorePointer(
          ignoring: !show,
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: AppMotion.fast,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleIconButton(
                        key: const ValueKey('video-back-10'),
                        icon: AppIcons.replay10,
                        tooltip: l10n.videoBack10,
                        onPressed: () => _skip(-_step),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      CircleIconButton(
                        icon: paused ? AppIcons.play : AppIcons.pause,
                        tooltip: paused
                            ? l10n.searchPreviewResume
                            : l10n.searchPreviewPause,
                        emphasized: true,
                        size: AppSizes.circleButtonLarge,
                        onPressed: () {
                          context.read<PreviewCubit>().togglePause();
                          if (!paused) _reveal();
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      CircleIconButton(
                        key: const ValueKey('video-forward-10'),
                        icon: AppIcons.forward10,
                        tooltip: l10n.videoForward10,
                        onPressed: () => _skip(_step),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.xs,
                  bottom: 0,
                  child: Row(
                    children: [
                      Text(
                        formatDuration(progress?.position ?? Duration.zero),
                        style: text,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: PreviewSeekLine(fraction: state.fraction)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        duration == null ? '' : formatDuration(duration),
                        style: text,
                      ),
                      if (!widget.fullscreen)
                        FullscreenVideoButton(
                          controls: (_) =>
                              const PreviewVideoControls(fullscreen: true),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

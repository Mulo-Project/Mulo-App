import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../../player/presentation/widgets/fullscreen_video.dart';
import '../bloc/preview_cubit.dart';
import '../../domain/entities/video_quality.dart';
import '../bloc/video_quality_cubit.dart';
import 'preview_control.dart';
import 'video_quality_sheet.dart';

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
                      _SkipButton(
                        key: const ValueKey('video-back-10'),
                        forward: false,
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
                      _SkipButton(
                        key: const ValueKey('video-forward-10'),
                        forward: true,
                        tooltip: l10n.videoForward10,
                        onPressed: () => _skip(_step),
                      ),
                    ],
                  ),
                ),
                // 옵션(반복 재생 · 화질) 버튼: 오른쪽 위.
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: CircleIconButton(
                        key: const ValueKey('video-options'),
                        icon: AppIcons.more,
                        tooltip: l10n.videoOptions,
                        onPressed: () {
                          _reveal();
                          showVideoOptions(context);
                        },
                      ),
                    ),
                  ),
                ),
                // 전체 화면의 닫기 버튼도 컨트롤과 같이 눌렀을 때만 보인다.
                if (widget.fullscreen)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: CircleIconButton(
                          icon: AppIcons.close,
                          tooltip: l10n.videoFullscreenExit,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
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

/// 10초 이동 버튼: 돌아가는 화살표 안에 숫자 10을 그려, 몇 초씩 움직이는지 한눈에 보이게 한다.
/// (앞으로는 같은 화살표를 좌우로 뒤집는다.)
class _SkipButton extends StatelessWidget {
  const _SkipButton({
    super.key,
    required this.forward,
    required this.tooltip,
    required this.onPressed,
  });

  final bool forward;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: AppSizes.circleButton / 2,
        child: SizedBox.square(
          dimension: AppSizes.circleButton,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.flip(
                flipX: forward,
                child: Icon(AppIcons.replay, size: 40, color: p.onSurface),
              ),
              Text(
                '10',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: p.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 영상 옵션 시트: 반복 재생 켜기 · 끄기, 화질 바꾸기 (고르면 바로 적용하고 닫는다).
Future<void> showVideoOptions(BuildContext context) {
  final preview = context.read<PreviewCubit>();
  final settingsQuality = context.read<VideoQualityCubit>().state;
  return showAppSheet<void>(
    context,
    builder: (sheetContext) => _VideoOptionsSheet(
      preview: preview,
      settingsQuality: settingsQuality,
    ),
  );
}

class _VideoOptionsSheet extends StatelessWidget {
  const _VideoOptionsSheet({
    required this.preview,
    required this.settingsQuality,
  });

  final PreviewCubit preview;
  final VideoQuality settingsQuality;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(l10n.videoOptionsTitle),
            const SizedBox(height: AppSpacing.sm),
            ValueListenableBuilder<bool>(
              valueListenable: preview.repeat,
              builder: (context, on, _) => InkWell(
                key: const ValueKey('video-option-repeat'),
                onTap: () => preview.repeat.value = !on,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm + AppSpacing.xxs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.videoRepeat, style: text.bodyLarge),
                      ),
                      AppSwitch(
                        value: on,
                        onChanged: (v) => preview.repeat.value = v,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.videoQualityTitle, style: text.titleSmall),
            ValueListenableBuilder<VideoQuality?>(
              valueListenable: preview.qualityOverride,
              builder: (context, override, _) {
                final current = override ?? settingsQuality;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final quality in VideoQuality.values)
                      InkWell(
                        key: ValueKey('video-option-quality-${quality.name}'),
                        onTap: () {
                          preview.qualityOverride.value = quality;
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm + AppSpacing.xxs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  videoQualityLabel(context, quality),
                                  style: text.bodyLarge?.copyWith(
                                    color: quality == current
                                        ? p.accent
                                        : p.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

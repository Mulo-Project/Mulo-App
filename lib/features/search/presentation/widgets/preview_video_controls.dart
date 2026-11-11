import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../player/presentation/widgets/fullscreen_video.dart';
import '../../../player/presentation/widgets/native_video.dart';
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
  const PreviewVideoControls({
    super.key,
    this.fullscreen = false,
    this.main = false,
  });

  final bool fullscreen;

  /// 미리 듣기가 아니라 메인 재생(현재 재생 목록)의 영상을 다룬다 (임시 저장한 영상). 같은 모양의 컨트롤이고,
  /// 재생 · 위치 · 10초 이동은 메인 플레이어가 하며 옵션에는 작은 창(PiP)만 있다.
  final bool main;

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
    if (widget.main) {
      final vm = context.read<NowPlayingCubit>();
      vm.seekTo(vm.state.position + delta);
    } else {
      context.read<PreviewCubit>().seekBy(delta);
    }
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
    final text = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.palette.onSurface);
    final (paused, position, duration, fraction, buffered) = widget.main
        ? context.select(
            (NowPlayingCubit c) => (
              !c.state.isPlaying,
              c.state.position,
              c.state.track?.duration,
              c.state.progress,
              0.0,
            ),
          )
        : context.select(
            (PreviewCubit c) => (
              c.state.paused,
              c.state.progress?.position ?? Duration.zero,
              c.state.progress?.duration,
              c.state.fraction,
              c.state.bufferedFraction,
            ),
          );
    final show = paused || _shown;
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
                      const SizedBox(width: AppSpacing.lg),
                      CircleIconButton(
                        icon: paused ? AppIcons.play : AppIcons.pause,
                        tooltip: paused
                            ? l10n.searchPreviewResume
                            : l10n.searchPreviewPause,
                        emphasized: true,
                        size: AppSizes.circleButtonLarge,
                        onPressed: () {
                          if (widget.main) {
                            context.read<NowPlayingCubit>().togglePlay();
                          } else {
                            context.read<PreviewCubit>().togglePause();
                          }
                          if (!paused) _reveal();
                        },
                      ),
                      const SizedBox(width: AppSpacing.lg),
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
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CircleIconButton(
                        key: const ValueKey('video-options'),
                        icon: AppIcons.more,
                        overlay: true,
                        tooltip: l10n.videoOptions,
                        onPressed: () {
                          _reveal();
                          showVideoOptions(context, main: widget.main);
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                  child: Row(
                    children: [
                      Text(formatDuration(position), style: text),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PreviewSeekLine(
                          fraction: fraction,
                          buffered: buffered,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        duration == null ? '' : formatDuration(duration),
                        style: text,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 확대 버튼 자리: 전체 화면에서는 축소(닫기) 버튼이 된다.
                      if (widget.fullscreen)
                        const FullscreenVideoButton(exit: true)
                      else
                        FullscreenVideoButton(
                          controls: (_) => PreviewVideoControls(
                            fullscreen: true,
                            main: widget.main,
                          ),
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
        child: Ink(
          width: AppSizes.circleButton,
          height: AppSizes.circleButton,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.scrim.withValues(alpha: .6),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.flip(
                flipX: forward,
                child: Icon(AppIcons.replay, size: 32, color: p.onSurface),
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
Future<void> showVideoOptions(BuildContext context, {bool main = false}) {
  final preview = context.read<PreviewCubit>();
  final settingsQuality = context.read<VideoQualityCubit>().state;
  // 가로(전체 화면)에서는 아래 시트가 영상을 가리고 옆으로만 넓어지므로, 오른쪽 패널로 연다.
  if (MediaQuery.orientationOf(context) == Orientation.landscape) {
    final palette = context.palette;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: palette.scrim.withValues(alpha: .4),
      transitionDuration: AppMotion.medium,
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 320,
          height: double.infinity,
          child: Material(
            color: palette.surface,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _VideoOptionsSheet(
                  preview: preview,
                  settingsQuality: settingsQuality,
                  main: main,
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: AppMotion.standard),
        ),
        child: child,
      ),
    );
  }
  return showAppSheet<void>(
    context,
    // 가로 전체 화면처럼 낮은 화면에서도 넘치지 않게 스크롤된다.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _VideoOptionsSheet(
      preview: preview,
      settingsQuality: settingsQuality,
      main: main,
    ),
  );
}

class _VideoOptionsSheet extends StatelessWidget {
  const _VideoOptionsSheet({
    required this.preview,
    required this.settingsQuality,
    this.main = false,
  });

  final PreviewCubit preview;
  final VideoQuality settingsQuality;

  /// 메인 재생의 영상이면 반복 · 화질 옵션은 없다 (반복은 재생 조작부, 화질은 저장할 때 정한다).
  final bool main;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(l10n.videoOptionsTitle),
            const SizedBox(height: AppSpacing.sm),
            if (!main)
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
            // 작은 창(PiP): 눌러서 바로 영상을 작은 창으로 띄운다.
            InkWell(
              key: const ValueKey('video-option-pip'),
              onTap: () {
                Navigator.of(context).pop();
                preview.enterPip();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.videoPip, style: text.bodyLarge)),
                    Icon(
                      AppIcons.fullscreenExit,
                      size: AppSizes.iconSm,
                      color: context.palette.onSurface,
                    ),
                  ],
                ),
              ),
            ),
            if (!main) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.videoQualityTitle, style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              // 화질은 가로로 스크롤되는 선택 버튼 줄이다 (시트가 길어지지 않는다).
              ValueListenableBuilder<VideoQuality?>(
                valueListenable: preview.qualityOverride,
                builder: (context, override, _) {
                  final current = override ?? settingsQuality;
                  return ChoiceChips(
                    items: [
                      for (final quality in VideoQuality.values)
                        ChoiceChipItem(
                          key: ValueKey('video-option-quality-${quality.name}'),
                          label: videoQualityLabel(context, quality),
                          selected: quality == current,
                          onTap: () {
                            preview.qualityOverride.value = quality;
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 메인 재생(현재 재생 목록)의 영상 + 미리 듣기 영상과 같은 컨트롤. 임시 저장한 영상 곡이 쓴다.
class MainVideoWithControls extends StatelessWidget {
  const MainVideoWithControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [NativeVideo(), PreviewVideoControls(main: true)],
    );
  }
}

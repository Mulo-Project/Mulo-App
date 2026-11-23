import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../search/presentation/widgets/preview_video_controls.dart';
import '../bloc/video_surface_cubit.dart';
import 'fullscreen_video.dart';

/// 영상 틀(사각 · 원 등)을 꽉 채워 보여 주고, 손가락으로 끌어 가려진 부분을 보고
/// 두 손가락으로 확대 · 축소한다. 축소는 영상 전체가 보이는 크기까지 되고, 두 번 누르면 틀 채우기로 돌아온다.
/// 영상 화면은 [NativeVideo]와 같은 텍스처를 쓴다.
class PanZoomVideo extends StatefulWidget {
  const PanZoomVideo({
    super.key,
    this.fullscreenOnTap = false,
    this.fullscreenButton = false,
  });

  /// 영상을 한 번 누르면 전체 화면으로 간다.
  final bool fullscreenOnTap;

  /// 오른쪽 아래에 전체 화면 버튼을 둔다.
  final bool fullscreenButton;

  static const maxScale = 4.0;

  @override
  State<PanZoomVideo> createState() => _PanZoomVideoState();
}

class _PanZoomVideoState extends State<PanZoomVideo> {
  late final VideoSurfaceCubit _surface;

  /// 틀을 꽉 채운 크기를 1로 둔 확대 배율, 그리고 가운데에서 얼마나 밀렸는지(px).
  var _scale = 1.0;
  var _offset = Offset.zero;
  var _startScale = 1.0;
  var _startOffset = Offset.zero;
  var _startFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _surface = context.read<VideoSurfaceCubit>();
    unawaited(_surface.acquire());
  }

  @override
  void dispose() {
    _surface.release();
    super.dispose();
  }

  /// 틀 [frame] 안에서 영상 [video]가 틀을 꽉 채우는 배율 / 영상 전체가 들어가는 배율의 비.
  static double _minScale(Size frame, Size video) {
    final fill = math.max(frame.width / video.width, frame.height / video.height);
    final fit = math.min(frame.width / video.width, frame.height / video.height);
    return fit / fill;
  }

  Offset _clamp(Offset o, Size frame, Size shown) {
    final mx = math.max(0.0, (shown.width - frame.width) / 2);
    final my = math.max(0.0, (shown.height - frame.height) / 2);
    return Offset(o.dx.clamp(-mx, mx), o.dy.clamp(-my, my));
  }

  void _fullscreen() => unawaited(
    showFullscreenVideo(
      context,
      controls: (_) => const PreviewVideoControls(fullscreen: true, main: true),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoSurfaceCubit, VideoSurfaceState>(
      builder: (context, s) {
        final id = s.textureId;
        if (id == null || s.width <= 0 || s.height <= 0) {
          return const SizedBox.shrink();
        }
        final video = Size(s.width.toDouble(), s.height.toDouble());
        return LayoutBuilder(
          builder: (context, c) {
            final frame = c.biggest;
            if (!frame.isFinite || frame.isEmpty) {
              return const SizedBox.shrink();
            }
            final fill = math.max(
              frame.width / video.width,
              frame.height / video.height,
            );
            final minScale = _minScale(frame, video);
            final scale = _scale.clamp(minScale, PanZoomVideo.maxScale);
            final shown = Size(
              video.width * fill * scale,
              video.height * fill * scale,
            );
            final offset = _clamp(_offset, frame, shown);
            return AnimatedOpacity(
              opacity: s.ready ? 1 : 0,
              duration: AppMotion.medium,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.fullscreenOnTap ? _fullscreen : null,
                    onDoubleTap: () => setState(() {
                      _scale = 1;
                      _offset = Offset.zero;
                    }),
                    onScaleStart: (d) {
                      _startScale = scale;
                      _startOffset = offset;
                      _startFocal = d.localFocalPoint;
                    },
                    onScaleUpdate: (d) => setState(() {
                      final next = (_startScale * d.scale).clamp(
                        minScale,
                        PanZoomVideo.maxScale,
                      );
                      final nextShown = Size(
                        video.width * fill * next,
                        video.height * fill * next,
                      );
                      _scale = next;
                      _offset = _clamp(
                        _startOffset + (d.localFocalPoint - _startFocal),
                        frame,
                        nextShown,
                      );
                    }),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned(
                            left: (frame.width - shown.width) / 2 + offset.dx,
                            top: (frame.height - shown.height) / 2 + offset.dy,
                            width: shown.width,
                            height: shown.height,
                            child: Texture(textureId: id),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.fullscreenButton)
                    Positioned(
                      right: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                      child: FullscreenVideoButton(
                        controls: (_) => const PreviewVideoControls(
                          fullscreen: true,
                          main: true,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

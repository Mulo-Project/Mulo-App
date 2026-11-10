import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../bloc/video_surface_cubit.dart';

/// 네이티브 플레이어가 소리와 같은 시계로 틀고 있는 영상 화면. 앱은 그리기만 한다.
/// 첫 화면이 그려지기 전에는 아무것도 그리지 않아서 뒤의 커버가 보이고, 그려지면 부드럽게 바뀐다.
/// 같은 화면을 미니 플레이어 · 상세 화면 · 플레이어가 나눠 쓰므로 화면을 옮겨도 이어서 보인다.
class NativeVideo extends StatefulWidget {
  const NativeVideo({super.key, this.fit = BoxFit.cover});

  /// 화면을 채우는 방식. 기본은 꽉 채우고 넘치는 부분을 자른다 (전체 화면은 contain으로 잘림 없이).
  final BoxFit fit;

  @override
  State<NativeVideo> createState() => _NativeVideoState();
}

class _NativeVideoState extends State<NativeVideo> {
  late final VideoSurfaceCubit _surface;

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoSurfaceCubit, VideoSurfaceState>(
      builder: (context, s) {
        final id = s.textureId;
        if (id == null || s.width <= 0 || s.height <= 0) {
          return const SizedBox.shrink();
        }
        return AnimatedOpacity(
          opacity: s.ready ? 1 : 0,
          duration: AppMotion.medium,
          child: FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: s.width.toDouble(),
              height: s.height.toDouble(),
              child: Texture(textureId: id),
            ),
          ),
        );
      },
    );
  }
}

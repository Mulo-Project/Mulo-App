import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../player/presentation/widgets/native_video.dart';
import '../../domain/entities/video_quality.dart';
import '../bloc/preview_video_cubit.dart';

/// 미리 듣는 곡의 영상 화면. 소리와 영상은 네이티브가 같은 시계로 틀고, 이 위젯은 영상을 읽어 틀라고 한 뒤 화면만 그린다.
/// 영상을 읽는 동안 · 못 읽었을 때는 아무것도 그리지 않아서 커버가 그대로 보인다.
class PreviewVideo extends StatelessWidget {
  const PreviewVideo({super.key, required this.pageUrl, this.quality});

  final String pageUrl;

  /// 저장한 곡이면 저장할 때 고른 화질 (저장한 데이터를 쓰려면 같은 화질로 읽어야 한다).
  final VideoQuality? quality;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('$pageUrl|${quality?.name}'),
      create: (_) => sl<PreviewVideoCubit>()..load(pageUrl, quality: quality),
      child: const _PreviewVideoBody(),
    );
  }
}

class _PreviewVideoBody extends StatelessWidget {
  const _PreviewVideoBody();

  @override
  Widget build(BuildContext context) {
    final started = context.select((PreviewVideoCubit c) => c.state.started);
    return started ? const NativeVideo() : const SizedBox.shrink();
  }
}

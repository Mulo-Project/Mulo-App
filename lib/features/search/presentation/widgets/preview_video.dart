import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../player/presentation/widgets/muted_video.dart';
import '../bloc/preview_cubit.dart';
import '../bloc/preview_video_cubit.dart';

/// 미리 듣는 곡의 영상 화면 (소리 없음). 소리는 미리 듣기 플레이어가 내고, 이 화면은 그 위치를 따라간다.
/// 영상을 읽는 동안 · 못 읽었을 때는 아무것도 그리지 않아서 커버가 그대로 보인다.
class PreviewVideo extends StatelessWidget {
  const PreviewVideo({super.key, required this.pageUrl});

  final String pageUrl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(pageUrl),
      create: (_) => sl<PreviewVideoCubit>()..load(pageUrl),
      child: const _PreviewVideoBody(),
    );
  }
}

class _PreviewVideoBody extends StatelessWidget {
  const _PreviewVideoBody();

  @override
  Widget build(BuildContext context) {
    final video = context.watch<PreviewVideoCubit>().state;
    final url = video.url;
    if (url == null) return const SizedBox.shrink();
    final preview = context.watch<PreviewCubit>().state;
    return MutedVideo(
      source: url,
      headers: video.headers,
      position: preview.progress?.position ?? Duration.zero,
      playing: !preview.paused,
    );
  }
}

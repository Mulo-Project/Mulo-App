import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../player/presentation/widgets/native_video.dart';
import '../../domain/entities/video_quality.dart';
import '../bloc/preview_video_cubit.dart';

/// 미리 듣는 곡의 영상 화면. 소리와 영상은 네이티브가 같은 시계로 틀고, 이 위젯은 영상을 읽어 틀라고 한 뒤 화면만 그린다.
/// 영상을 읽는 동안 · 못 읽었을 때는 아무것도 그리지 않아서 커버가 그대로 보인다.
class PreviewVideo extends StatefulWidget {
  const PreviewVideo({
    super.key,
    required this.pageUrl,
    this.quality,
    this.online = false,
    this.followMain = false,
  });

  final String pageUrl;

  /// 저장한 곡이면 저장할 때 고른 화질 (저장한 데이터를 쓰려면 같은 화질로 읽어야 한다).
  /// 화질만 바뀌면 영상 화면을 그대로 둔 채 새 화질로 바꿔 끼운다 (처음 화면으로 돌아가지 않는다).
  final VideoQuality? quality;

  /// 소리만 저장한 곡도 영상을 읽어 보인다 (상세 화면에서만. 못 읽으면 커버가 그대로 보인다).
  final bool online;

  /// 메인 재생 소리(임시 저장한 음원)에 맞춰 영상을 튼다.
  final bool followMain;

  @override
  State<PreviewVideo> createState() => _PreviewVideoState();
}

class _PreviewVideoState extends State<PreviewVideo> {
  late final PreviewVideoCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PreviewVideoCubit>();
    _load(keepFrame: false);
  }

  void _load({required bool keepFrame}) {
    _cubit.load(
      widget.pageUrl,
      quality: widget.quality,
      online: widget.online,
      followMain: widget.followMain,
      keepFrame: keepFrame,
    );
  }

  @override
  void didUpdateWidget(PreviewVideo old) {
    super.didUpdateWidget(old);
    final sameSource =
        old.pageUrl == widget.pageUrl &&
        old.online == widget.online &&
        old.followMain == widget.followMain;
    if (sameSource && old.quality == widget.quality) return;
    _load(keepFrame: sameSource);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _cubit, child: const _PreviewVideoBody());
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

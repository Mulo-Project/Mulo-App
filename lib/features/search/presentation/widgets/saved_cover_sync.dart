import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/saved_video.dart';
import '../bloc/saved_videos_cubit.dart';

/// 임시 저장한 음원의 썸네일을 곡 커버로 알려 준다: 미니 플레이어 · 곡 줄 · 알림이 파일 곡과 같은 경로로 그린다.
/// DB에는 저장하지 않고(임시 커버), 저장 목록이 바뀔 때마다 맞춘다.
class SavedCoverSync extends StatefulWidget {
  const SavedCoverSync({super.key, required this.child});

  final Widget child;

  @override
  State<SavedCoverSync> createState() => _SavedCoverSyncState();
}

class _SavedCoverSyncState extends State<SavedCoverSync> {
  static final _prefix = CoverKey.track(Track.savedIdPrefix);

  void _sync(List<SavedVideo> videos) {
    context.read<CoverCubit>().syncTemporary(_prefix, {
      for (final v in videos)
        if (v.hit.thumbnailUrl case final url? when url.isNotEmpty)
          CoverKey.track('${Track.savedIdPrefix}${v.id}'): CoverArt.web(url),
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync(context.read<SavedVideosCubit>().state);
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<SavedVideosCubit, List<SavedVideo>>(
        listener: (_, videos) => _sync(videos),
        child: widget.child,
      );
}

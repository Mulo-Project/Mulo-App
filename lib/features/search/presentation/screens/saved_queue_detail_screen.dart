import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../domain/entities/media_info.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/saved_videos_cubit.dart';
import '../saved_track.dart';
import 'media_detail_screen.dart';

/// 저장한 음원 화면의 타일에서 연다: 플레이어 화면 하나가 열리고, 썸네일 자리에 그 곡의 다운로드 상세가 먼저 보인다
/// (재생 중인 곡이 일반 곡이어도 타일을 누른 곡을 보여 준다. 일반 곡으로 넘어가면 플레이어 모양으로 돌아간다).
Future<void> showSavedQueueDetail(BuildContext context, MediaHit hit) =>
    context.push<void>(Routes.player, extra: hit);

class SavedQueueDetailScreen extends StatefulWidget {
  const SavedQueueDetailScreen({super.key, required this.hit});

  /// 처음 보여 줄 곡 (목록이 재생되기 전에도, 끝난 뒤에도 마지막으로 본 곡을 그대로 둔다).
  final MediaHit hit;

  @override
  State<SavedQueueDetailScreen> createState() => _SavedQueueDetailScreenState();
}

class _SavedQueueDetailScreenState extends State<SavedQueueDetailScreen> {
  late MediaHit _hit = widget.hit;

  @override
  Widget build(BuildContext context) {
    // 메인 재생이 임시 저장한 음원을 듣는 중이면 곡이 넘어갈 때 이 화면도 그 곡으로 따라간다.
    final trackId = context.select((NowPlayingCubit c) => c.state.track?.id);
    final savedId = trackId == null ? null : savedVideoIdOf(trackId);
    if (savedId != null) {
      final match = context.read<SavedVideosCubit>().state.where(
        (v) => v.id == savedId,
      );
      if (match.isNotEmpty) _hit = match.first.hit;
    }
    return Scaffold(
      backgroundColor: context.palette.background,
      body: MediaDetailScreen(
        key: ValueKey(_hit.id),
        hit: _hit,
        fromSaved: true,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/media_info.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/saved_videos_cubit.dart';
import '../saved_track.dart';
import 'media_detail_screen.dart';

/// 저장한 음원 화면의 타일에서 여는 상세 화면: 일반 상세 화면에 재생 목록 조작부를 늘 붙인다.
/// 메인 재생 대기열에서 곡이 넘어가면(이전 · 다음 · 자동) 화면도 그 곡의 상세로 따라간다.
Future<void> showSavedQueueDetail(BuildContext context, MediaHit hit) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'saved-queue-detail'),
      builder: (_) => SavedQueueDetailScreen(hit: hit),
    ),
  );
}

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

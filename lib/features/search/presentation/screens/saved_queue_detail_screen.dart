import 'dart:async';

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

/// 저장한 음원 화면의 타일에서 여는 상세 화면: 일반 상세 화면에 재생 목록 조작부를 늘 붙인다.
/// 메인 재생 대기열에서 곡이 넘어가면(이전 · 다음 · 자동) 화면도 그 곡의 상세로 따라간다.
Future<void> showSavedQueueDetail(BuildContext context, MediaHit hit) =>
    pushSavedQueueDetail(Navigator.of(context, rootNavigator: true), hit);

/// [showSavedQueueDetail]과 같되 화면(context) 없이 내비게이터로 연다 (알림 · 곡 전환처럼 앱 바깥 신호로 열 때).
/// 이미 저장 상세가 맨 위에 있으면 또 열지 않는다 (곡이 바뀌면 그 화면이 스스로 따라간다).
Future<void> pushSavedQueueDetail(NavigatorState navigator, MediaHit hit) {
  Route<dynamic>? top;
  navigator.popUntil((route) {
    top = route;
    return true;
  });
  if (top?.settings.name == 'saved-queue-detail') return Future.value();
  return navigator.push<void>(
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
    return BlocListener<NowPlayingCubit, NowPlayingState>(
      // 일반 곡으로 넘어갔다: 저장 타일에서 연 이 화면을 닫고 플레이어 화면으로 간다
      // (플레이어 화면 안에서 넘어갈 때는 그 화면이 스스로 모양을 바꾼다).
      listenWhen: (a, b) =>
          a.track?.id != b.track?.id &&
          b.track != null &&
          savedVideoIdOf(b.track!.id) == null,
      listener: (context, _) {
        final route = ModalRoute.of(context);
        if (route?.settings.name != 'saved-queue-detail') return;
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        unawaited(router.push(Routes.player));
      },
      child: Scaffold(
        backgroundColor: context.palette.background,
        body: MediaDetailScreen(
          key: ValueKey(_hit.id),
          hit: _hit,
          fromSaved: true,
        ),
      ),
    );
  }
}

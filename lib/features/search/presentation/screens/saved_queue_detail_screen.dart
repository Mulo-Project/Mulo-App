import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/media_info.dart';
import '../bloc/preview_cubit.dart';
import 'media_detail_screen.dart';

/// 저장한 음원 화면의 타일에서 여는 상세 화면: 일반 상세 화면에 재생 목록 조작부를 늘 붙인다.
/// 목록 재생 중 곡이 넘어가면(이전 · 다음 · 자동) 화면도 그 곡의 상세로 따라간다.
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
    final preview = context.read<PreviewCubit>();
    return ListenableBuilder(
      listenable: Listenable.merge([preview.queueItems, preview.queuePos]),
      builder: (context, _) {
        final items = preview.queueItems.value;
        final pos = preview.queuePos.value;
        if (items.isNotEmpty) _hit = items[pos.clamp(0, items.length - 1)].hit;
        return Scaffold(
          backgroundColor: context.palette.background,
          body: MediaDetailScreen(
            key: ValueKey(_hit.id),
            hit: _hit,
            fromSaved: true,
          ),
        );
      },
    );
  }
}

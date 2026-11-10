import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../bloc/preview_cubit.dart';
import 'media_detail_screen.dart';

/// 저장한 음원 재생 목록을 듣는 동안 보는 화면: 지금 곡의 상세 화면에 아래 목록 조작 줄을 붙인다.
/// 곡이 넘어가면 화면도 다음 곡의 상세 화면으로 바뀐다.
Future<void> showSavedQueueDetail(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'saved-queue-detail'),
      builder: (_) => const SavedQueueDetailScreen(),
    ),
  );
}

class SavedQueueDetailScreen extends StatefulWidget {
  const SavedQueueDetailScreen({super.key});

  @override
  State<SavedQueueDetailScreen> createState() => _SavedQueueDetailScreenState();
}

class _SavedQueueDetailScreenState extends State<SavedQueueDetailScreen> {
  bool _closing = false;

  /// 목록이 한 번이라도 채워진 적이 있다 (열자마자 비어 있는 건 곧 채워질 것이라 닫지 않는다).
  bool _seen = false;

  @override
  Widget build(BuildContext context) {
    final preview = context.read<PreviewCubit>();
    final p = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([preview.queueItems, preview.queuePos]),
      builder: (context, _) {
        final items = preview.queueItems.value;
        final pos = preview.queuePos.value;
        if (items.isNotEmpty) _seen = true;
        if (items.isEmpty) {
          // 목록이 끝났거나 멈췄다: 이 화면을 닫는다.
          if (_seen && !_closing) {
            _closing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).maybePop();
            });
          }
          return Scaffold(backgroundColor: p.background);
        }
        final hit = items[pos.clamp(0, items.length - 1)].hit;
        return Scaffold(
          backgroundColor: p.background,
          body: Column(
            children: [
              // 아래 고정 조작부는 상세 화면이 지금 듣는 곡일 때 스스로 붙인다 (SavedQueueControls).
              Expanded(
                child: MediaDetailScreen(key: ValueKey(hit.id), hit: hit),
              ),
            ],
          ),
        );
      },
    );
  }
}

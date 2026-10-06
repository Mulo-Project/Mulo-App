import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../bloc/download_queue_cubit.dart';

/// 받기가 끝난 곡이 생기면 커버 · 색을 다시 읽는다 (받는 쪽 저장소가 DB에 직접 넣으므로
/// 메모리에 든 커버 목록에는 아직 없다). 보관함 목록은 DB를 구독하고 있어 따로 하지 않는다.
class DownloadCompletionListener extends StatelessWidget {
  const DownloadCompletionListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<DownloadQueueCubit, DownloadQueueState>(
        listenWhen: (a, b) => b.doneCount > a.doneCount,
        listener: (context, _) {
          context.read<CoverCubit>().load();
          context.read<CoverColorCubit>().load();
        },
        child: child,
      );
}

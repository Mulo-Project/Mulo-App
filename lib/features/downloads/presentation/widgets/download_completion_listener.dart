import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/diagnostics/diag_notice.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../domain/usecases/download_usecases.dart';
import '../bloc/download_queue_cubit.dart';

/// 받기가 끝난 곡이 생기면 커버 · 색을 다시 읽는다 (받는 쪽 저장소가 DB에 직접 넣으므로
/// 메모리에 든 커버 목록에는 아직 없다). 보관함 목록은 DB를 구독하고 있어 따로 하지 않는다.
/// 받은 곡의 파일 태그를 쓰지 못했으면 snackbar로 알린다 (이유를 함께 보인다).
class DownloadCompletionListener extends StatefulWidget {
  const DownloadCompletionListener({super.key, required this.child});

  final Widget child;

  @override
  State<DownloadCompletionListener> createState() =>
      _DownloadCompletionListenerState();
}

class _DownloadCompletionListenerState
    extends State<DownloadCompletionListener> {
  StreamSubscription<Object?>? _sub;
  StreamSubscription<String>? _diagSub;

  /// 임시 진단: 디버그 빌드에서는 태그를 쓴 결과도 snackbar로 보인다.
  static const _showSuccess = kDebugMode;

  @override
  void initState() {
    super.initState();
    _listenDiag();
    _sub = sl<WatchTagNotices>()(const NoParams()).listen((n) {
      if (!mounted) return;
      if (n.ok && !_showSuccess) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final text = n.ok
          ? '[tag] ${n.extension} OK · ${n.title}'
          : '${context.l10n.downloadTagFailed(n.title)}\n[${n.extension}] ${n.detail}';
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            duration: Duration(seconds: n.ok ? 3 : 20),
          ),
        );
    });
  }

  /// 임시 진단 알림 (디버그 빌드 전용).
  void _listenDiag() {
    if (!kDebugMode) return;
    _diagSub = DiagNotice.stream.listen((m) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(m), duration: const Duration(seconds: 20)),
        );
    });
  }

  @override
  void dispose() {
    _diagSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<DownloadQueueCubit, DownloadQueueState>(
        listenWhen: (a, b) => b.doneCount > a.doneCount,
        listener: (context, _) {
          context.read<CoverCubit>().load();
          context.read<CoverColorCubit>().load();
        },
        child: widget.child,
      );
}

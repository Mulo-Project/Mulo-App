import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/engine_notice.dart';
import '../../domain/usecases/engine_usecases.dart';

/// 받기가 엔진 버전 때문에 실패하면 snackbar로 알린다 (앱이 알아서 업데이트하므로 잠시 뒤 다시 받으라고 안내).
class EngineNoticeListener extends StatefulWidget {
  const EngineNoticeListener({super.key, required this.child});

  final Widget child;

  @override
  State<EngineNoticeListener> createState() => _EngineNoticeListenerState();
}

class _EngineNoticeListenerState extends State<EngineNoticeListener> {
  StreamSubscription<EngineNotice>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = sl<WatchEngineNotices>()(const NoParams()).listen((notice) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final text = switch (notice) {
        EngineNotice.outdated => context.l10n.downloadEngineOutdated,
      };
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 8)),
        );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

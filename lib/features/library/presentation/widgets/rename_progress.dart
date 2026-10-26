import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 오래 걸리는 곡 정보 일괄 수정 동안 진행 대화상자를 띄운다 (끌 수 없다).
/// [task]는 곡을 하나 끝낼 때마다 `report(끝낸 수, 전체 수)`를 불러 진행도를 알린다.
/// 끝나면 대화상자를 닫고 [task]의 결과를 돌려준다.
Future<T> showProgressWhile<T>(
  BuildContext context, {
  required Future<T> Function(void Function(int done, int total) report) task,
  String Function(AppLocalizations l10n)? title,
  String Function(AppLocalizations l10n, int done, int total)? count,
}) async {
  final progress = ValueNotifier<(int, int)>((0, 0));
  final navigator = Navigator.of(context, rootNavigator: true);
  // 대화상자는 기다리지 않고 띄운 채로 일을 시작한다.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: ValueListenableBuilder<(int, int)>(
        valueListenable: progress,
        builder: (context, p, _) {
          final l10n = context.l10n;
          return AppDialog(
            title: title?.call(l10n) ?? l10n.renameProgressTitle,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressLine(value: p.$2 == 0 ? 0 : p.$1 / p.$2, height: 6),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  count?.call(l10n, p.$1, p.$2) ??
                      l10n.renameProgressCount(p.$1, p.$2),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: const [],
          );
        },
      ),
    ),
  );
  try {
    return await task((done, total) => progress.value = (done, total));
  } finally {
    navigator.pop();
  }
}

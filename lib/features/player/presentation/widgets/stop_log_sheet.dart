import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/stop_log_cubit.dart';

/// 재생이 멈춘 이유 기록을 바텀 시트로 연다 (최신이 위).
Future<void> showStopLogSheet(BuildContext context) => showAppSheet<void>(
  context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => BlocProvider(
    create: (_) => sl<StopLogCubit>()..load(),
    child: const _StopLogSheet(),
  ),
);

class _StopLogSheet extends StatelessWidget {
  const _StopLogSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final lines = context.watch<StopLogCubit>().state;
    return Padding(
      padding: appSheetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(
              l10n.settingsStopLog,
              subtitle: l10n.settingsStopLogDesc,
            ),
            const SizedBox(height: AppSpacing.md),
            if (lines == null)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: LoadingIndicator()),
              )
            else if (lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.stopLogEmpty,
                  style: text.bodyMedium?.copyWith(
                    color: context.palette.onSurfaceMuted,
                  ),
                ),
              )
            else ...[
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lines.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) =>
                      SelectableText(lines[i], style: text.bodyMedium),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PlainButton(
                label: l10n.stopLogClear,
                onPressed: context.read<StopLogCubit>().clear,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

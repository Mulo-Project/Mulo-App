import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/track.dart';
import '../bloc/hidden_records_cubit.dart';

/// 숨긴 곡 기록 목록: 곡마다 지우기 · 모두 지우기 (바텀 시트).
Future<void> showHiddenRecordsSheet(BuildContext context) {
  final cubit = context.read<HiddenRecordsCubit>();
  return showAppSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const HiddenRecordsSheet(),
    ),
  );
}

class HiddenRecordsSheet extends StatelessWidget {
  const HiddenRecordsSheet({super.key});

  Future<void> _purge(
    BuildContext context, {
    Track? only,
    required int count,
  }) async {
    final l10n = context.l10n;
    final cubit = context.read<HiddenRecordsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmDialog(
      context,
      title: only == null
          ? l10n.settingsPurgeHiddenTitle
          : l10n.hiddenRecordsPurgeOneTitle(only.title),
      body: only == null
          ? l10n.settingsPurgeHiddenBody(count)
          : l10n.settingsPurgeHiddenBody(1),
      confirmLabel: l10n.settingsPurgeHidden,
      cancelLabel: l10n.actionCancel,
    );
    if (!ok) return;
    final n = only == null
        ? await cubit.purge()
        : await cubit.purgeOne(only.id);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsPurgeHiddenDone(n))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tracks = context.watch<HiddenRecordsCubit>().state;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: Padding(
          padding: appSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              AppSheetTitle(
                l10n.settingsPurgeHidden,
                subtitle: tracks.isEmpty
                    ? null
                    : l10n.hiddenRecordsHint(tracks.length),
              ),
              const SizedBox(height: AppSpacing.md),
              if (tracks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    l10n.settingsPurgeHiddenNone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.palette.onSurfaceMuted,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in tracks)
                        _HiddenRow(
                          track: t,
                          onPurge: () => _purge(
                            context,
                            only: t,
                            count: tracks.length,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              if (tracks.isNotEmpty)
                PillButton(
                  label: l10n.hiddenRecordsPurgeAll,
                  icon: AppIcons.delete,
                  onPressed: () => _purge(context, count: tracks.length),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenRow extends StatelessWidget {
  const _HiddenRow({required this.track, required this.onPurge});

  final Track track;
  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.hair),
                Text(
                  track.artist,
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          RowIconButton(
            icon: AppIcons.close,
            tooltip: context.l10n.settingsPurgeHidden,
            onPressed: onPurge,
          ),
        ],
      ),
    );
  }
}

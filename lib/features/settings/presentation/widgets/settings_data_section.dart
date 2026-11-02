import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/bloc/hidden_records_cubit.dart';
import 'settings_common.dart';

/// 데이터 묶음: 폴더를 빼서 숨겨 둔 곡의 기록 정리.
class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  Future<void> _purge(BuildContext context, int count) async {
    final l10n = context.l10n;
    final cubit = context.read<HiddenRecordsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.settingsPurgeHiddenTitle,
      body: l10n.settingsPurgeHiddenBody(count),
      confirmLabel: l10n.settingsPurgeHidden,
      cancelLabel: l10n.actionCancel,
    );
    if (!ok) return;
    final n = await cubit.purge();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsPurgeHiddenDone(n))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => sl<HiddenRecordsCubit>()..load(),
      child: BlocBuilder<HiddenRecordsCubit, int>(
        builder: (context, count) => SectionCard(
          title: l10n.settingsData,
          children: [
            SettingRow(
              title: l10n.settingsPurgeHidden,
              description: count == 0
                  ? l10n.settingsPurgeHiddenNone
                  : l10n.settingsPurgeHiddenDesc(count),
              trailing: const SettingsChevron(),
              onTap: count == 0 ? null : () => _purge(context, count),
            ),
          ],
        ),
      ),
    );
  }
}

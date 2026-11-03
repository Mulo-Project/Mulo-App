import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/bloc/hidden_records_cubit.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import 'hidden_records_sheet.dart';
import 'settings_common.dart';

/// 데이터 묶음: 폴더를 빼서 숨겨 둔 곡의 기록 정리.
class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  Future<void> _purge(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<HiddenRecordsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    // 설정 탭이 살아 있는 동안 폴더를 뺐을 수 있으니 누를 때 다시 센다.
    await cubit.load();
    final count = cubit.state;
    if (count == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsPurgeHiddenNone)),
      );
      return;
    }
    if (!context.mounted) return;
    // 지우기 전에 어떤 곡의 기록이 남았는지 보여 준다. "기록 지우기"를 눌러야 확인 창으로 간다.
    final tracks = await cubit.tracks();
    if (!context.mounted) return;
    if (!await showHiddenRecordsSheet(context, tracks)) return;
    if (!context.mounted) return;
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
      // 폴더를 빼거나 다시 불러와 보관함이 바뀌면 숨긴 곡 수를 다시 센다.
      child: BlocListener<LibraryCubit, LibraryState>(
        listenWhen: (a, b) => a.revision != b.revision,
        listener: (context, _) => context.read<HiddenRecordsCubit>().load(),
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
                onTap: () => _purge(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/bloc/hidden_records_cubit.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../library/presentation/widgets/hidden_records_sheet.dart';
import 'settings_common.dart';

/// 데이터 묶음: 폴더를 빼서 숨겨 둔 곡의 기록 정리 (눌러서 목록 시트를 연다).
class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => sl<HiddenRecordsCubit>()..load(),
      // 폴더를 빼거나 다시 불러와 보관함이 바뀌면 숨긴 곡 수를 다시 센다.
      child: BlocListener<LibraryCubit, LibraryState>(
        listenWhen: (a, b) => a.revision != b.revision,
        listener: (context, _) => context.read<HiddenRecordsCubit>().load(),
        child: BlocBuilder<HiddenRecordsCubit, List<Track>>(
          builder: (context, hidden) => SectionCard(
            title: l10n.settingsData,
            children: [
              SettingRow(
                title: l10n.settingsPurgeHidden,
                description: hidden.isEmpty
                    ? l10n.settingsPurgeHiddenNone
                    : l10n.settingsPurgeHiddenDesc(hidden.length),
                trailing: const SettingsChevron(),
                onTap: () => showHiddenRecordsSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

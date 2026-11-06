import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../downloads/domain/entities/download_options.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../downloads/presentation/bloc/download_preferences_cubit.dart';
import '../../../downloads/presentation/bloc/download_settings_cubit.dart';
import '../../../downloads/presentation/widgets/save_folder_sheet.dart';
import '../../../engine/presentation/bloc/engine_cubit.dart';
import '../../../library/presentation/widgets/loaded_folders_tile.dart';

import 'settings_common.dart';
import 'settings_engine_sections.dart';

/// 다운로드 묶음: 저장 위치 · 불러오는 폴더 · 엔진 · 포맷.
class SettingsDownloadSection extends StatefulWidget {
  const SettingsDownloadSection({super.key, required this.engine});

  final EngineCubit engine;

  @override
  State<SettingsDownloadSection> createState() =>
      _SettingsDownloadSectionState();
}

class _SettingsDownloadSectionState extends State<SettingsDownloadSection> {
  /// 이 기기에서 고를 수 있는 저장 형식 (OS별 정책, 불러오기 전엔 비어 있다).
  List<AudioFormat> _formats = const [];

  @override
  void initState() {
    super.initState();
    sl<GetSelectableFormats>()(const NoParams()).then((formats) {
      if (!mounted) return;
      setState(() => _formats = formats);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final savePath = context.watch<DownloadSettingsCubit>().state;
    final prefs = context.watch<DownloadPreferencesCubit>().state;
    return SectionCard(
      title: l10n.settingsDownload,
      children: [
        SettingRow(
          title: l10n.settingsSavePath,
          description: savePath.isEmpty ? l10n.settingsSavePathDesc : savePath,
          trailing: const SettingsChevron(),
          onTap: () async {
            final cubit = context.read<DownloadSettingsCubit>();
            // 체크한 폴더 = 항상 받는 기본 위치. 체크를 풀면 마지막에 받은 폴더가 기준.
            await showSaveFolderSheet(
              context,
              current: savePath,
              pickOther: cubit.pickFolder,
              removable: true,
              onFixedChanged: (path) =>
                  path == null ? cubit.clearSavePath() : cubit.setSavePath(path),
            );
          },
        ),
        const LoadedFoldersTile(),
        SettingsEngineRow(cubit: widget.engine),
        if (_formats.isNotEmpty)
          SettingRow(
            title: l10n.settingsFormat,
            below: SegmentedPills<AudioFormat>(
              expand: true,
              values: _formats,
              selected: prefs.format,
              labelOf: (f) => f.name,
              onChanged: context.read<DownloadPreferencesCubit>().setFormat,
            ),
          ),
      ],
    );
  }
}

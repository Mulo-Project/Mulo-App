import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/app_info.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/widgets/stop_log_sheet.dart';
import 'settings_common.dart';

/// 정보 묶음: 앱 버전.
class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: l10n.settingsAbout,
      children: [
        SettingRow(
          title: l10n.settingsVersion,
          trailing: Text(
            appVersion,
            style: text.bodyMedium?.copyWith(
              color: context.palette.onSurfaceMuted,
            ),
          ),
        ),
        // 재생 중단 기록은 Android 재생 서비스가 남긴다. 그 밖의 OS에서는 줄을 숨긴다.
        if (Platform.isAndroid)
          SettingRow(
            title: l10n.settingsStopLog,
            description: l10n.settingsStopLogDesc,
            trailing: const SettingsChevron(),
            onTap: () => showStopLogSheet(context),
          ),
      ],
    );
  }
}

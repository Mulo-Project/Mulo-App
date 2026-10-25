import 'package:flutter/material.dart';

import '../../../../core/app_info.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

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
      ],
    );
  }
}

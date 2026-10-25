import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 설정 줄 오른쪽의 "더 보기" 화살표.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(AppIcons.chevronRight, color: context.palette.onSurfaceMuted);
}

String presetLabel(AppLocalizations l10n, ThemePreset preset) =>
    switch (preset) {
      ThemePreset.violet => l10n.themeViolet,
      ThemePreset.coral => l10n.themeCoral,
      ThemePreset.ocean => l10n.themeOcean,
      ThemePreset.forest => l10n.themeForest,
      ThemePreset.sunset => l10n.themeSunset,
      ThemePreset.rose => l10n.themeRose,
      ThemePreset.gold => l10n.themeGold,
      ThemePreset.ice => l10n.themeIce,
    };

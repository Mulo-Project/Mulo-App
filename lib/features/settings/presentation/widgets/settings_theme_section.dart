import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/player_style_cubit.dart';
import '../../../player/presentation/widgets/player_style_sheet.dart';
import '../../../theme/domain/entities/theme_settings.dart';
import '../../../theme/presentation/bloc/theme_cubit.dart';

import 'settings_common.dart';

/// 테마 묶음: 미리보기 · 곡 분위기 따라가기 · 모드 · 색 · 플레이어 모양.
class SettingsThemeSection extends StatelessWidget {
  const SettingsThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedPreset = context.select((ThemeCubit c) => c.state.preset);
    final mode = context.select((ThemeCubit c) => c.state.mode);
    final followMood = context.select((ThemeCubit c) => c.state.followMood);
    final brightness = Theme.of(context).brightness;
    final themeCtrl = context.read<ThemeCubit>();
    return SectionCard(
      title: l10n.settingsTheme,
      children: [
        SettingRow(
          title: l10n.settingsThemePreview,
          description: l10n.settingsThemePreviewDesc,
          trailing: const SettingsChevron(),
          // 곡 분위기 따라가기 중에는 색이 곡마다 정해지므로 프리셋 미리보기는 쓰지 않는다.
          onTap: followMood
              ? null
              : () {
                  themeCtrl.beginPreview();
                  context.go(Routes.home);
                },
        ),
        SettingRow(
          title: l10n.settingsFollowMood,
          description: l10n.settingsFollowMoodDesc,
          trailing: AppSwitch(
            value: followMood,
            onChanged: themeCtrl.setFollowMood,
          ),
        ),
        SettingRow(
          title: l10n.settingsAppearance,
          below: SegmentedPills<AppThemeMode>(
            expand: true,
            values: AppThemeMode.values,
            selected: mode,
            labelOf: (m) => switch (m) {
              AppThemeMode.dark => l10n.appearanceDark,
              AppThemeMode.light => l10n.appearanceLight,
            },
            onChanged: themeCtrl.selectMode,
          ),
        ),
        SettingRow(
          title: l10n.settingsThemeColor,
          description: followMood ? l10n.settingsThemeColorFollowing : null,
          below: Opacity(
            opacity: followMood ? .4 : 1,
            child: IgnorePointer(
              ignoring: followMood,
              // 한 줄에 4개씩 칸을 똑같이 나눠 가운데에 둔다 (왼쪽으로 몰리지 않게).
              child: Column(
                children: [
                  for (
                    var row = 0;
                    row < ThemePreset.values.length;
                    row += 4
                  ) ...[
                    if (row > 0) const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (var i = row; i < row + 4; i++)
                          Expanded(
                            child: i < ThemePreset.values.length
                                ? Center(
                                    child: ThemeSwatch(
                                      preview: ThemePreset.values[i].paletteFor(
                                        brightness,
                                      ),
                                      label: presetLabel(
                                        l10n,
                                        ThemePreset.values[i],
                                      ),
                                      selected:
                                          ThemePreset.values[i] ==
                                          selectedPreset,
                                      onTap: () => themeCtrl.selectPreset(
                                        ThemePreset.values[i],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SettingRow(
          title: l10n.playerStyleTitle,
          below: SegmentedPills<PlayerStyle>(
            expand: true,
            values: PlayerStyle.values,
            selected: context.watch<PlayerStyleCubit>().state,
            labelOf: (s) => playerStyleName(l10n, s),
            onChanged: context.read<PlayerStyleCubit>().select,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/sample/sample_data.dart';
import '../../../downloads/domain/entities/download_options.dart';
import '../../../downloads/presentation/bloc/download_settings_cubit.dart';
import '../../../library/presentation/widgets/loaded_folders_tile.dart';
import '../../../player/presentation/bloc/player_style_cubit.dart';
import '../../../player/presentation/screens/player_style_screen.dart'
    show playerStyleName;
import '../../../security/presentation/bloc/app_lock_cubit.dart';
import '../../../security/presentation/screens/pin_entry_screen.dart';
import '../../../theme/domain/entities/theme_settings.dart';
import '../../../theme/presentation/bloc/theme_cubit.dart';

enum DownloadMode { server, local }

/// 설정 (상세 기능: 서버 연결·모드 선택 #31, 저장 위치 #23, 기본 음질·포맷 #24,
/// 다운로드 엔진 업데이트 #25, 알림 곡 정보 숨기기 #32 + 테마 D-005).
/// 테마 색(프리셋, 저장됨)과 앱 잠금(PIN · 생체 인증)만 실제로 동작하고 나머지는 자리 표시.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Quality _quality = Quality.best;
  AudioFormat _format = AudioFormat.m4a;
  bool _hideNotification = false;
  bool _followMood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final selectedPreset = context.select((ThemeCubit c) => c.state.preset);
    final mode = context.select((ThemeCubit c) => c.state.mode);
    final brightness = Theme.of(context).brightness;
    final themeCtrl = context.read<ThemeCubit>();
    final lock = context.watch<AppLockCubit>().state;
    final lockCtrl = context.read<AppLockCubit>();
    final savePath = context.watch<DownloadSettingsCubit>().state;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            large: true,
            title: l10n.navSettings,
            subtitle: l10n.settingsSubtitle,
          ),
          Padding(
            padding: AppSpacing.screen,
            child: Column(
              children: [
                SectionCard(
                  title: l10n.settingsServer,
                  children: [
                    SettingRow(
                      title: l10n.settingsConnection,
                      trailing: StatusPill(label: l10n.settingsDisconnected),
                    ),
                    SettingRow(
                      title: l10n.settingsMode,
                      description: l10n.settingsModeLiteNote,
                      below: SegmentedPills<DownloadMode>(
                        expand: true,
                        values: DownloadMode.values,
                        selected: DownloadMode.server,
                        labelOf: (m) => switch (m) {
                          DownloadMode.server => l10n.settingsModeServer,
                          DownloadMode.local => l10n.settingsModeLocal,
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  title: l10n.settingsDownload,
                  children: [
                    SettingRow(
                      title: l10n.settingsSavePath,
                      description: savePath.isEmpty
                          ? l10n.settingsSavePathDesc
                          : savePath,
                      trailing: const _Chevron(),
                      onTap: context.read<DownloadSettingsCubit>().pickAndSave,
                    ),
                    const LoadedFoldersTile(),
                    SettingRow(
                      title: l10n.settingsQuality,
                      below: SegmentedPills<Quality>(
                        expand: true,
                        values: Quality.values,
                        selected: _quality,
                        labelOf: (q) => switch (q) {
                          Quality.best => l10n.qualityBest,
                          Quality.normal => l10n.qualityNormal,
                          Quality.saver => l10n.qualitySaver,
                        },
                        onChanged: (q) => setState(() => _quality = q),
                      ),
                    ),
                    SettingRow(
                      title: l10n.settingsFormat,
                      below: SegmentedPills<AudioFormat>(
                        expand: true,
                        values: AudioFormat.values,
                        selected: _format,
                        labelOf: (f) => f.name,
                        onChanged: (f) => setState(() => _format = f),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  title: l10n.settingsEngine,
                  children: [
                    SettingRow(
                      title: 'yt-dlp',
                      description: l10n.settingsEngineVersion(
                        SampleData.engineCurrent,
                        SampleData.engineLatest,
                      ),
                      trailing: PillButton(
                        label: l10n.settingsEngineUpdate,
                        compact: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  title: l10n.settingsSecurity,
                  children: [
                    SettingRow(
                      title: l10n.settingsAppLock,
                      description: l10n.settingsAppLockDesc,
                      trailing: AppSwitch(
                        value: lock.enabled,
                        onChanged: (on) => PinEntryScreen.open(
                          context,
                          on ? PinEntryMode.create : PinEntryMode.disable,
                        ),
                      ),
                    ),
                    if (lock.enabled)
                      SettingRow(
                        title: l10n.settingsChangePin,
                        description: l10n.settingsChangePinDesc,
                        trailing: const _Chevron(),
                        onTap: () =>
                            PinEntryScreen.open(context, PinEntryMode.change),
                      ),
                    if (lock.enabled && lock.biometricAvailable)
                      SettingRow(
                        title: l10n.settingsBiometric,
                        description: l10n.settingsBiometricDesc,
                        trailing: AppSwitch(
                          value: lock.biometricEnabled,
                          onChanged: (on) => lockCtrl.setBiometricEnabled(
                            on,
                            reason: l10n.biometricReason,
                          ),
                        ),
                      ),
                    SettingRow(
                      title: l10n.settingsHideNotification,
                      description: l10n.settingsHideNotificationDesc,
                      trailing: AppSwitch(
                        value: _hideNotification,
                        onChanged: (v) => setState(() => _hideNotification = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  title: l10n.settingsTheme,
                  children: [
                    SettingRow(
                      title: l10n.settingsThemePreview,
                      description: l10n.settingsThemePreviewDesc,
                      trailing: const _Chevron(),
                      onTap: () {
                        themeCtrl.beginPreview();
                        context.go(Routes.home);
                      },
                    ),
                    SettingRow(
                      title: l10n.settingsPlayerStyle,
                      description: playerStyleName(
                        l10n,
                        context.watch<PlayerStyleCubit>().state,
                      ),
                      trailing: const _Chevron(),
                      onTap: () => context.push(Routes.playerTheme),
                    ),
                    SettingRow(
                      title: l10n.settingsFollowMood,
                      description: l10n.settingsFollowMoodDesc,
                      trailing: AppSwitch(
                        value: _followMood,
                        onChanged: (v) => setState(() => _followMood = v),
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
                      below: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final preset in ThemePreset.values)
                            ThemeSwatch(
                              preview: preset.paletteFor(brightness),
                              label: presetLabel(l10n, preset),
                              selected: preset == selectedPreset,
                              onTap: () => themeCtrl.selectPreset(preset),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  title: l10n.settingsAbout,
                  children: [
                    SettingRow(
                      title: l10n.settingsVersion,
                      trailing: Text(
                        SampleData.appVersion,
                        style: text.bodyMedium?.copyWith(
                          color: context.palette.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right_rounded, color: context.palette.onSurfaceMuted);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/sample/sample_data.dart';
import '../../downloads/domain/download_options.dart';

enum DownloadMode { server, local }

/// 설정 (상세 기능: 서버 연결·모드 선택 #31, 저장 위치 #23, 기본 음질·포맷 #24,
/// 다운로드 엔진 업데이트 #25, 알림 곡 정보 숨기기 #32 + 테마 D-005).
/// 테마 색(프리셋, 저장됨)만 실제로 동작하고 나머지는 자리 표시.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Quality _quality = Quality.best;
  AudioFormat _format = AudioFormat.m4a;
  bool _hideNotification = false;
  bool _followMood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final selectedPreset = ref.watch(
      themeControllerProvider.select((s) => s.preset),
    );
    final mode = ref.watch(themeControllerProvider.select((s) => s.mode));
    final brightness = Theme.of(context).brightness;
    final themeCtrl = ref.read(themeControllerProvider.notifier);

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
                      title: l10n.settingsServerAddress,
                      description: l10n.settingsServerNotSet,
                      trailing: const _Chevron(),
                      onTap: () {},
                    ),
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
                      description: SampleData.savePath,
                      trailing: const _Chevron(),
                      onTap: () {},
                    ),
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
                  title: l10n.settingsPlayback,
                  children: [
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
                    SettingRow(
                      title: l10n.settingsDesignPreview,
                      trailing: const _Chevron(),
                      onTap: () => context.push(Routes.designPreview),
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

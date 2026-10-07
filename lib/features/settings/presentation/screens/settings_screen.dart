import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/app_info.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../downloads/domain/entities/download_options.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../downloads/presentation/bloc/download_settings_cubit.dart';
import '../../../engine/presentation/bloc/engine_cubit.dart';
import '../../../library/presentation/widgets/loaded_folders_tile.dart';
import '../../../notifications/presentation/bloc/notification_settings_cubit.dart';
import '../../../player/presentation/bloc/player_style_cubit.dart';
import '../../../player/presentation/widgets/player_style_sheet.dart';
import '../../../security/presentation/bloc/app_lock_cubit.dart';
import '../../../security/presentation/screens/pin_entry_screen.dart';
import '../../../theme/domain/entities/theme_settings.dart';
import '../../../theme/presentation/bloc/theme_cubit.dart';

enum DownloadMode { server, local }

/// 설정 (상세 기능: 서버 연결·모드 선택 #31, 저장 위치 #23, 기본 음질·포맷 #24,
/// 다운로드 엔진 업데이트 #25, 알림 곡 정보 숨기기 #32 + 테마 D-005).
/// 테마 색(프리셋, 저장됨) · 앱 잠금(PIN · 생체 인증) · 알림 설정만 실제로 동작하고 나머지는 자리 표시.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Quality _quality = Quality.best;
  AudioFormat _format = AudioFormat.opus;

  /// 이 기기에서 고를 수 있는 저장 형식 (OS별 정책, 불러오기 전엔 비어 있다).
  List<AudioFormat> _formats = const [];
  bool _followMood = false;
  late final EngineCubit _engine = sl<EngineCubit>()..load();

  @override
  void initState() {
    super.initState();
    sl<GetSelectableFormats>()(const NoParams()).then((formats) {
      if (!mounted) return;
      setState(() {
        _formats = formats;
        if (!formats.contains(_format) && formats.isNotEmpty) {
          _format = formats.first;
        }
      });
    });
  }

  @override
  void dispose() {
    _engine.close();
    super.dispose();
  }

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
    final notify = context.watch<NotificationSettingsCubit>().state;
    final notifyCtrl = context.read<NotificationSettingsCubit>();

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
                _ServerSection(cubit: _engine),
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
                    _EngineRow(cubit: _engine),
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
                    if (_formats.isNotEmpty)
                      SettingRow(
                        title: l10n.settingsFormat,
                        below: SegmentedPills<AudioFormat>(
                          expand: true,
                          values: _formats,
                          selected: _format,
                          labelOf: (f) => f.name,
                          onChanged: (f) => setState(() => _format = f),
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
                        value: notify.settings.hideSongInfo,
                        onChanged: notifyCtrl.setHideSongInfo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  title: l10n.settingsNotifications,
                  children: [
                    if (!notify.permissionGranted)
                      SettingRow(
                        title: l10n.settingsNotifyPermission,
                        description: l10n.settingsNotifyPermissionDesc,
                        trailing: PillButton(
                          compact: true,
                          label: l10n.settingsNotifyOpenSettings,
                          onPressed: notifyCtrl.openSystemSettings,
                        ),
                      ),
                    SettingRow(
                      title: l10n.settingsNotifyDownloadProgress,
                      description: l10n.settingsNotifyDownloadProgressDesc,
                      trailing: AppSwitch(
                        value: notify.settings.downloadProgress,
                        onChanged: notifyCtrl.setDownloadProgress,
                      ),
                    ),
                    SettingRow(
                      title: l10n.settingsNotifyDownloadResult,
                      description: l10n.settingsNotifyDownloadResultDesc,
                      trailing: AppSwitch(
                        value: notify.settings.downloadResult,
                        onChanged: notifyCtrl.setDownloadResult,
                      ),
                    ),
                    SettingRow(
                      title: l10n.settingsNotifyPlayback,
                      description: l10n.settingsNotifyPlaybackDesc,
                      trailing: AppSwitch(
                        value: notify.settings.playback,
                        onChanged: notifyCtrl.setPlayback,
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
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
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

/// 서버 묶음: 지금 쓰는 모드(엔진 상태로 정해짐)와 서버 주소가 빌드에 있는지를 보여 준다.
/// 모드는 자동으로 정해져서 바꾸는 버튼은 없다 (로컬 yt-dlp를 쓸 수 있으면 로컬).
class _ServerSection extends StatelessWidget {
  const _ServerSection({required this.cubit});

  final EngineCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<EngineCubit, EngineState>(
      bloc: cubit,
      builder: (context, state) {
        final status = state.status;
        final localReady =
            status != null && status.supported && status.installed;
        return SectionCard(
          title: l10n.settingsServer,
          children: [
            SettingRow(
              title: l10n.settingsConnection,
              trailing: StatusPill(
                label: AppConfig.hasApiBaseUrl
                    ? l10n.settingsServerConfigured
                    : l10n.settingsDisconnected,
              ),
            ),
            SettingRow(
              title: l10n.settingsMode,
              description: status != null && !status.supported
                  ? l10n.settingsModeLiteNote
                  : null,
              below: SegmentedPills<DownloadMode>(
                expand: true,
                values: DownloadMode.values,
                selected: localReady ? DownloadMode.local : DownloadMode.server,
                labelOf: (m) => switch (m) {
                  DownloadMode.server => l10n.settingsModeServer,
                  DownloadMode.local => l10n.settingsModeLocal,
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 다운로드 엔진(yt-dlp) 줄: 설치 여부 · 버전, 설치 · 업데이트 버튼 (데스크톱 · Android full).
class _EngineRow extends StatelessWidget {
  const _EngineRow({required this.cubit});

  final EngineCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<EngineCubit, EngineState>(
      bloc: cubit,
      builder: (context, state) {
        final status = state.status;
        if (status == null || !status.supported) return const SizedBox.shrink();
        final description = state.busy
            ? l10n.settingsEngineInstalling
            : state.failed
            ? l10n.settingsEngineFailed
            : status.installed
            ? l10n.settingsEngineInstalled(status.version ?? '')
            : l10n.settingsEngineNotInstalled;
        return SettingRow(
          title: l10n.settingsEngine,
          description: description,
          trailing: PillButton(
            compact: true,
            label: status.installed
                ? l10n.settingsEngineUpdate
                : l10n.settingsEngineInstall,
            onPressed: state.busy ? null : cubit.install,
          ),
        );
      },
    );
  }
}

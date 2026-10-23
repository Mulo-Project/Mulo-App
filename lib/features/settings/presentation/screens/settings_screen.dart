import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../lyrics/presentation/bloc/lyrics_settings_cubit.dart';
import '../../../lyrics/presentation/screens/lyrics_latency_screen.dart';
import '../../../../app/router.dart';
import '../../../../core/app_info.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../account/domain/entities/google_account.dart';
import '../../../account/presentation/bloc/account_cubit.dart';
import '../../../downloads/domain/entities/download_options.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../downloads/presentation/bloc/download_preferences_cubit.dart';
import '../../../downloads/presentation/bloc/download_settings_cubit.dart';
import '../../../downloads/presentation/widgets/save_folder_dialog.dart';
import '../../../engine/presentation/bloc/engine_cubit.dart';
import '../../../equalizer/presentation/bloc/equalizer_cubit.dart';
import '../../../equalizer/presentation/widgets/device_equalizer_section.dart';
import '../../../library/presentation/widgets/loaded_folders_tile.dart';
import '../../../notifications/presentation/bloc/notification_settings_cubit.dart';
import '../../../permissions/presentation/widgets/permissions_section.dart';
import '../../../player/presentation/bloc/mix_with_others_cubit.dart';
import '../../../player/presentation/bloc/output_behavior_cubit.dart';
import '../../../player/presentation/bloc/player_style_cubit.dart';
import '../../../player/presentation/widgets/player_style_sheet.dart';
import '../../../security/presentation/bloc/app_lock_cubit.dart';
import '../../../security/presentation/screens/pin_entry_screen.dart';
import '../../../subscriptions/presentation/widgets/subscriptions_section.dart';
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
  /// 이 기기에서 고를 수 있는 저장 형식 (OS별 정책, 불러오기 전엔 비어 있다).
  List<AudioFormat> _formats = const [];
  late final EngineCubit _engine = sl<EngineCubit>()..load();

  @override
  void initState() {
    super.initState();
    sl<GetSelectableFormats>()(const NoParams()).then((formats) {
      if (!mounted) return;
      setState(() {
        _formats = formats;
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
    final followMood = context.select((ThemeCubit c) => c.state.followMood);
    final brightness = Theme.of(context).brightness;
    final themeCtrl = context.read<ThemeCubit>();
    final lock = context.watch<AppLockCubit>().state;
    final lockCtrl = context.read<AppLockCubit>();
    final savePath = context.watch<DownloadSettingsCubit>().state;
    final prefs = context.watch<DownloadPreferencesCubit>().state;
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
          // 묶음 안 줄이 이미 좌우 [AppSpacing.md]를 두므로 바깥 여백 없이 상단 제목과 왼쪽 선을 맞춘다.
          Column(
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
                    onTap: () async {
                      final cubit = context.read<DownloadSettingsCubit>();
                      final path = await showSaveFolderDialog(
                        context,
                        current: savePath,
                        pickOther: cubit.pickFolder,
                      );
                      if (path != null) await cubit.setSavePath(path);
                    },
                  ),
                  const LoadedFoldersTile(),
                  _EngineRow(cubit: _engine),
                  SettingRow(
                    title: l10n.settingsQuality,
                    below: SegmentedPills<Quality>(
                      expand: true,
                      values: Quality.values,
                      selected: prefs.quality,
                      labelOf: (q) => switch (q) {
                        Quality.best => l10n.qualityBest,
                        Quality.normal => l10n.qualityNormal,
                        Quality.saver => l10n.qualitySaver,
                      },
                      onChanged: context
                          .read<DownloadPreferencesCubit>()
                          .setQuality,
                    ),
                  ),
                  if (_formats.isNotEmpty)
                    SettingRow(
                      title: l10n.settingsFormat,
                      below: SegmentedPills<AudioFormat>(
                        expand: true,
                        values: _formats,
                        selected: prefs.format,
                        labelOf: (f) => f.name,
                        onChanged: context
                            .read<DownloadPreferencesCubit>()
                            .setFormat,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _AccountSection(),
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
                    title: l10n.settingsBackgroundDownload,
                    description: l10n.settingsBackgroundDownloadDesc,
                    trailing: AppSwitch(
                      value: notify.settings.backgroundDownload,
                      onChanged: notifyCtrl.setBackgroundDownload,
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
                title: l10n.settingsPlayback,
                children: [
                  SettingRow(
                    title: l10n.settingsMixWithOthers,
                    description: l10n.settingsMixWithOthersDesc,
                    trailing: AppSwitch(
                      value: context.watch<MixWithOthersCubit>().state,
                      onChanged: context.read<MixWithOthersCubit>().set,
                    ),
                  ),
                  // 출력 기기 동작은 Android 재생 서비스가 처리한다. 그 밖의 OS에서는 줄을 숨긴다.
                  if (context.watch<OutputBehaviorCubit>().supported) ...[
                    SettingRow(
                      title: l10n.settingsPauseOnDisconnect,
                      description: l10n.settingsPauseOnDisconnectDesc,
                      trailing: AppSwitch(
                        value: context
                            .watch<OutputBehaviorCubit>()
                            .state
                            .pauseOnDisconnect,
                        onChanged: context
                            .read<OutputBehaviorCubit>()
                            .setPauseOnDisconnect,
                      ),
                    ),
                    SettingRow(
                      title: l10n.settingsResumeOnConnect,
                      description: l10n.settingsResumeOnConnectDesc,
                      trailing: AppSwitch(
                        value: context
                            .watch<OutputBehaviorCubit>()
                            .state
                            .resumeOnConnect,
                        onChanged: context
                            .read<OutputBehaviorCubit>()
                            .setResumeOnConnect,
                      ),
                    ),
                    SettingRow(
                      title: l10n.settingsResumeWithoutNotification,
                      description: l10n.settingsResumeWithoutNotificationDesc,
                      trailing: AppSwitch(
                        value: context
                            .watch<OutputBehaviorCubit>()
                            .state
                            .resumeWithoutNotification,
                        onChanged: context
                            .read<OutputBehaviorCubit>()
                            .setResumeWithoutNotification,
                      ),
                    ),
                  ],
                  // 이퀄라이저를 쓸 수 없는 환경(Android 밖)에서는 줄을 숨긴다.
                  if (context.watch<EqualizerCubit>().state.supported)
                    SettingRow(
                      title: l10n.equalizerTitle,
                      description:
                          context.watch<EqualizerCubit>().state.settings.enabled
                          ? l10n.equalizerOn
                          : l10n.equalizerOff,
                      trailing: const _Chevron(),
                      onTap: () => context.push(Routes.equalizer),
                    ),
                  SettingRow(
                    title: l10n.lyricsLatencyTitle,
                    description: l10n.lyricsLatencySeconds(
                      (context.watch<LyricsSettingsCubit>().state.latencyMs /
                              1000)
                          .toStringAsFixed(2),
                    ),
                    trailing: const _Chevron(),
                    onTap: () => showLyricsLatency(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const DeviceEqualizerSection(),
              const SubscriptionsSection(),
              const SizedBox(height: AppSpacing.lg),
              const PermissionsSection(),
              SectionCard(
                title: l10n.settingsTheme,
                children: [
                  SettingRow(
                    title: l10n.settingsThemePreview,
                    description: l10n.settingsThemePreviewDesc,
                    trailing: const _Chevron(),
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
                    description: followMood
                        ? l10n.settingsThemeColorFollowing
                        : null,
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
                              if (row > 0)
                                const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  for (var i = row; i < row + 4; i++)
                                    Expanded(
                                      child: i < ThemePreset.values.length
                                          ? Center(
                                              child: ThemeSwatch(
                                                preview: ThemePreset.values[i]
                                                    .paletteFor(brightness),
                                                label: presetLabel(
                                                  l10n,
                                                  ThemePreset.values[i],
                                                ),
                                                selected:
                                                    ThemePreset.values[i] ==
                                                    selectedPreset,
                                                onTap: () =>
                                                    themeCtrl.selectPreset(
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

/// 계정 묶음: 구글 계정으로 로그인 · 로그아웃 (내 유튜브 재생목록을 불러오는 데 쓴다).
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AccountCubit>().state;
    final cubit = context.read<AccountCubit>();
    final account = state.account;
    final String description;
    if (account != null) {
      description = account.displayName == null || account.displayName!.isEmpty
          ? account.email
          : '${account.displayName} · ${account.email}';
    } else if (state.failure != null) {
      description = l10n.settingsAccountFailed;
    } else {
      description = switch (state.support) {
        AccountSupport.available => l10n.settingsAccountSignedOutDesc,
        AccountSupport.notConfigured => l10n.settingsAccountNotConfigured(
          AppConfig.googleRequiredKeys,
        ),
        AccountSupport.unsupportedPlatform => l10n.settingsAccountUnsupported,
      };
    }
    return SectionCard(
      title: l10n.settingsAccount,
      children: [
        SettingRow(
          title: l10n.settingsGoogleAccount,
          description: description,
          trailing: account != null
              ? PillButton(
                  compact: true,
                  label: l10n.settingsAccountSignOut,
                  variant: PillVariant.tonal,
                  onPressed: state.busy ? null : cubit.signOut,
                )
              : PillButton(
                  compact: true,
                  label: l10n.settingsAccountSignIn,
                  onPressed:
                      state.busy || state.support != AccountSupport.available
                      ? null
                      : cubit.signIn,
                ),
        ),
      ],
    );
  }
}

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

  Future<void> _confirmRemove(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.settingsEngineRemoveTitle,
      body: l10n.settingsEngineRemoveBody,
      confirmLabel: l10n.settingsEngineRemove,
      cancelLabel: l10n.actionCancel,
    );
    if (ok) await cubit.remove();
  }

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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 앱이 받아 둔 엔진만 지울 수 있다 (PATH의 yt-dlp · Android 내장은 지우지 않는다).
              if (status.removable)
                PlainButton(
                  label: l10n.settingsEngineRemove,
                  onPressed: state.busy ? null : () => _confirmRemove(context),
                ),
              PillButton(
                compact: true,
                label: status.installed
                    ? l10n.settingsEngineUpdate
                    : l10n.settingsEngineInstall,
                onPressed: state.busy ? null : cubit.install,
              ),
            ],
          ),
        );
      },
    );
  }
}

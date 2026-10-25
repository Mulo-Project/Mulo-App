import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../notifications/presentation/bloc/notification_settings_cubit.dart';

/// 알림 묶음: 권한 · 받기 · 재생 알림.
class SettingsNotificationSection extends StatelessWidget {
  const SettingsNotificationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notify = context.watch<NotificationSettingsCubit>().state;
    final notifyCtrl = context.read<NotificationSettingsCubit>();
    return SectionCard(
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
    );
  }
}

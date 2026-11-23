import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../notifications/presentation/bloc/notification_settings_cubit.dart';
import '../../../security/presentation/bloc/app_lock_cubit.dart';
import '../../../security/presentation/screens/pin_entry_screen.dart';

import 'settings_common.dart';

/// 보안 묶음: 앱 잠금 · 알림의 곡 정보 숨기기.
class SettingsSecuritySection extends StatelessWidget {
  const SettingsSecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lock = context.watch<AppLockCubit>().state;
    final lockCtrl = context.read<AppLockCubit>();
    final notify = context.watch<NotificationSettingsCubit>().state;
    final notifyCtrl = context.read<NotificationSettingsCubit>();
    return SectionCard(
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
            trailing: const SettingsChevron(),
            onTap: () => PinEntryScreen.open(context, PinEntryMode.change),
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
    );
  }
}

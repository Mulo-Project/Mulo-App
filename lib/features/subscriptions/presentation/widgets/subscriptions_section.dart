import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/background_status.dart';
import '../../domain/entities/subscription_settings.dart';
import '../bloc/subscriptions_cubit.dart';

/// 설정 화면의 "구독" 묶음: 구독 채널 목록으로 가기와 새 영상 확인 설정.
/// 백그라운드 확인(주기 · 와이파이 전용)은 Android에서만 보인다.
class SubscriptionsSection extends StatefulWidget {
  const SubscriptionsSection({super.key});

  @override
  State<SubscriptionsSection> createState() => _SubscriptionsSectionState();
}

class _SubscriptionsSectionState extends State<SubscriptionsSection> {
  late final SubscriptionsCubit _cubit = sl<SubscriptionsCubit>()
    ..load().then((_) => _cubit.refreshStatus());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
      bloc: _cubit,
      builder: (context, state) {
        final s = state.settings;
        return SectionCard(
          title: l10n.settingsSubscriptions,
          children: [
            SettingRow(
              title: l10n.settingsSubscriptionChannels,
              description: l10n.subscriptionsCount(state.channels.length),
              trailing: Icon(AppIcons.chevronRight, color: p.onSurfaceMuted),
              onTap: () => context.push(Routes.subscriptions),
            ),
            SettingRow(
              title: l10n.settingsCheckOnLaunch,
              description: l10n.settingsCheckOnLaunchDesc,
              trailing: AppSwitch(
                value: s.checkOnLaunch,
                onChanged: _cubit.setCheckOnLaunch,
              ),
            ),
            if (Platform.isAndroid) ...[
              SettingRow(
                title: l10n.settingsBackgroundCheck,
                description: l10n.settingsBackgroundCheckDesc,
                trailing: AppSwitch(
                  value: s.background,
                  onChanged: _cubit.setBackground,
                ),
              ),
              if (s.background) ...[
                SettingRow(
                  title: l10n.settingsCheckInterval,
                  below: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: SegmentedPills<int>(
                      values: SubscriptionSettings.intervals,
                      selected: s.intervalHours,
                      labelOf: l10n.settingsCheckIntervalHours,
                      onChanged: _cubit.setIntervalHours,
                      expand: true,
                    ),
                  ),
                ),
                SettingRow(
                  title: l10n.settingsCheckWifiOnly,
                  description: l10n.settingsCheckWifiOnlyDesc,
                  trailing: AppSwitch(
                    value: s.wifiOnly,
                    onChanged: _cubit.setWifiOnly,
                  ),
                ),
              ],
              if (state.hasEnabled)
                SettingRow(
                  title: state.checking
                      ? l10n.settingsCheckNowChecking
                      : l10n.settingsCheckNow,
                  description: _statusText(context, state.status),
                  trailing: Icon(AppIcons.refresh, color: p.onSurfaceMuted),
                  onTap: state.checking ? null : _cubit.checkNow,
                ),
            ],
          ],
        );
      },
    );
  }

  /// 마지막 확인 결과를 한두 줄로: 안 오는 이유(알림 막힘 · 읽기 실패 · 예약 안 됨)가 먼저 보이게.
  String _statusText(BuildContext context, BackgroundStatus? s) {
    final l10n = context.l10n;
    if (s == null || s.lastRunAt == null) {
      return [
        l10n.settingsCheckStatusNever,
        if (s != null && s.notificationsBlocked)
          l10n.settingsCheckStatusBlocked,
      ].join('\n');
    }
    final time = DateFormat.MMMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(s.lastRunAt!);
    return [
      l10n.settingsCheckStatusLast(time),
      if (s.notified > 0) l10n.settingsCheckStatusNotified(s.notified),
      if (s.failedChannels > 0)
        l10n.settingsCheckStatusFailed(s.failedChannels),
      if (s.notificationsBlocked || s.blocked) l10n.settingsCheckStatusBlocked,
      if (_cubit.state.settings.background && !s.scheduled)
        l10n.settingsCheckStatusNotScheduled,
    ].join('\n');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/permissions_cubit.dart';

/// 설정 목록의 "권한" 묶음. 권한마다 토글 한 줄. 이 기기에 따로 허용할 권한이 없으면 아무것도 그리지 않는다.
class PermissionsSection extends StatefulWidget {
  const PermissionsSection({super.key});

  @override
  State<PermissionsSection> createState() => _PermissionsSectionState();
}

class _PermissionsSectionState extends State<PermissionsSection>
    with WidgetsBindingObserver {
  late final PermissionsCubit _cubit = sl<PermissionsCubit>()..refresh();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cubit.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<PermissionsCubit, PermissionsState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state.levels.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: SectionCard(
            title: l10n.settingsPermissions,
            children: [
              for (final entry in state.levels.entries)
                SettingRow(
                  title: _title(l10n, entry.key),
                  description: _description(l10n, entry.key, entry.value),
                  trailing: AppSwitch(
                    value: entry.value == PermissionLevel.granted,
                    onChanged: (_) => _cubit.toggle(entry.key),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _title(AppLocalizations l10n, AppPermission p) => switch (p) {
    AppPermission.notifications => l10n.permNotifications,
    AppPermission.audio => l10n.permAudio,
  };

  String _description(
    AppLocalizations l10n,
    AppPermission p,
    PermissionLevel level,
  ) {
    if (level == PermissionLevel.blocked) return l10n.permBlockedDesc;
    return switch (p) {
      AppPermission.notifications => l10n.permNotificationsDesc,
      AppPermission.audio => l10n.permAudioDesc,
    };
  }
}

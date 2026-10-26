import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../engine/presentation/bloc/engine_cubit.dart';

/// 다운로드 방식(서버 · 로컬).
enum DownloadMode { server, local }

class SettingsServerSection extends StatelessWidget {
  const SettingsServerSection({super.key, required this.cubit});

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
class SettingsEngineRow extends StatelessWidget {
  const SettingsEngineRow({super.key, required this.cubit});

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

  Future<void> _confirmRevert(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.settingsEngineRevertTitle,
      body: l10n.settingsEngineRevertBody,
      confirmLabel: l10n.settingsEngineRevert,
      cancelLabel: l10n.actionCancel,
    );
    if (ok) await cubit.revert();
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
            ? (state.reverting
                  ? l10n.settingsEngineReverting
                  : l10n.settingsEngineInstalling)
            : state.failed
            ? (state.reverting
                  ? l10n.settingsEngineRevertFailed
                  : l10n.settingsEngineFailed)
            : status.installed
            ? (status.version == null
                  ? l10n.settingsEngineBundled
                  : l10n.settingsEngineInstalled(status.version!))
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
              // 업데이트한 yt-dlp만 앱에 들어 있던 버전으로 되돌릴 수 있다 (Android full).
              if (status.revertible)
                PlainButton(
                  label: l10n.settingsEngineRevert,
                  onPressed: state.busy ? null : () => _confirmRevert(context),
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

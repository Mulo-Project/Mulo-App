import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../lyrics/presentation/bloc/lyrics_settings_cubit.dart';
import '../../../lyrics/presentation/screens/lyrics_latency_screen.dart';
import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../equalizer/presentation/bloc/equalizer_cubit.dart';
import '../../../player/presentation/bloc/mix_with_others_cubit.dart';
import '../../../player/presentation/bloc/output_behavior_cubit.dart';

import 'settings_common.dart';
import 'settings_lyrics_file_row.dart';

/// 재생 묶음: 다른 앱과 같이 재생 · 출력 기기 동작 · 이퀄라이저 · 반응 시간 보정.
class SettingsPlaybackSection extends StatelessWidget {
  const SettingsPlaybackSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
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
              value: context.watch<OutputBehaviorCubit>().state.resumeOnConnect,
              onChanged: context.read<OutputBehaviorCubit>().setResumeOnConnect,
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
            description: context.watch<EqualizerCubit>().state.settings.enabled
                ? l10n.equalizerOn
                : l10n.equalizerOff,
            trailing: const SettingsChevron(),
            onTap: () => context.push(Routes.equalizer),
          ),
        SettingRow(
          title: l10n.lyricsLatencyTitle,
          description: l10n.lyricsLatencySeconds(
            (context.watch<LyricsSettingsCubit>().state.latencyMs / 1000)
                .toStringAsFixed(2),
          ),
          trailing: const SettingsChevron(),
          onTap: () => showLyricsLatency(context),
        ),
        const SettingsLyricsFileRow(),
      ],
    );
  }
}

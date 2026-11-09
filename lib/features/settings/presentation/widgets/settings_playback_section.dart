import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:go_router/go_router.dart';

import '../../../lyrics/presentation/bloc/lyrics_settings_cubit.dart';
import '../../../lyrics/presentation/screens/lyrics_latency_screen.dart';
import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../equalizer/presentation/bloc/equalizer_cubit.dart';
import '../../../player/presentation/bloc/mix_with_others_cubit.dart';
import '../../../player/presentation/bloc/output_behavior_cubit.dart';

import '../../../library/presentation/widgets/track_menu.dart'
    show toggleLyricsOverlay;
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../player/presentation/widgets/player_sleep_timer.dart';
import '../../../search/presentation/bloc/video_quality_cubit.dart';
import '../../../search/presentation/widgets/video_quality_sheet.dart';

import 'settings_common.dart';

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
          title: l10n.videoQualityTitle,
          description: videoQualityLabel(
            context,
            context.watch<VideoQualityCubit>().state,
          ),
          trailing: const SettingsChevron(),
          onTap: () => showVideoQualitySheet(context),
        ),
        // 수면 타이머: 플레이어 화면과 같은 시간 고르기 대화상자를 연다.
        SettingRow(
          title: l10n.playerSleepTimer,
          description: _sleepDescription(context),
          trailing: const SettingsChevron(),
          onTap: () => showSleepTimerPicker(
            context,
            context.read<NowPlayingCubit>(),
          ),
        ),
        // 떠 있는 가사 창은 Android만. 한 번 켜 두면 설정이 저장되어 앱을 다시 켜도 곡을 재생하면 뜬다.
        if (defaultTargetPlatform == TargetPlatform.android)
          SettingRow(
            title: l10n.settingsLyricsOverlay,
            description: l10n.settingsLyricsOverlayDesc,
            trailing: AppSwitch(
              value: context.watch<LyricsSettingsCubit>().state.overlay,
              onChanged: (_) => toggleLyricsOverlay(context),
            ),
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
      ],
    );
  }

  /// 수면 타이머 줄 설명: 켜져 있으면 남은 분, 아니면 "꺼짐".
  String _sleepDescription(BuildContext context) {
    final l10n = context.l10n;
    final endsAt = context.select((NowPlayingCubit c) => c.state.sleepEndsAt);
    if (endsAt == null) return l10n.settingsSleepTimerOff;
    final left = endsAt.difference(DateTime.now());
    if (left.isNegative) return l10n.settingsSleepTimerOff;
    return l10n.playerSleepTimerMinutes((left.inSeconds / 60).ceil());
  }
}

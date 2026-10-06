import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../bloc/preview_cubit.dart';

/// [hit] 미리 듣기를 시작하거나(이미 듣는 중이면) 멈춘다.
/// 소리가 나기 시작하면 메인 재생은 멈추고, 시작하지 못하면 안내를 띄운다.
Future<void> togglePreview(BuildContext context, MediaHit hit) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final preview = context.read<PreviewCubit>();
  final nowPlaying = context.read<NowPlayingCubit>();

  final failure = await preview.toggle(hit);
  if (failure != null) {
    // 까닭을 알 수 있게 엔진이 알려 준 마지막 줄을 덧붙인다.
    final detail = preview.lastFailureDetail
        .split('\n')
        .map((l) => l.trim())
        .lastWhere((l) => l.isNotEmpty, orElse: () => '');
    final message = switch (failure) {
      EngineFailure.unavailable => l10n.searchPreviewUnavailable,
      EngineFailure.network => l10n.searchNetworkBody,
      EngineFailure.notFound => l10n.searchNotFoundBody,
      _ => l10n.searchPreviewFailed,
    };
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          detail.isEmpty || failure == EngineFailure.unavailable
              ? message
              : '$message\n${detail.length > 240 ? detail.substring(0, 240) : detail}',
        ),
      ),
    );
    return;
  }
  // 두 소리가 겹치지 않게 메인 재생은 미리 듣기가 시작될 때 멈춘다.
  final state = preview.state;
  if (state.isActive(hit.id) &&
      state.status == PreviewStatus.playing &&
      nowPlaying.state.isPlaying) {
    nowPlaying.togglePlay();
  }
}

/// 상세 화면의 미리 듣기 버튼. 준비 중이거나 듣는 중이면 누를 때 멈춘다.
class PreviewButton extends StatelessWidget {
  const PreviewButton({super.key, required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = context.select(
      (PreviewCubit c) =>
          c.state.isActive(hit.id) ? c.state.status : PreviewStatus.idle,
    );
    return PillButton(
      label: switch (status) {
        PreviewStatus.idle => l10n.searchPreview,
        PreviewStatus.loading => l10n.searchPreviewLoading,
        PreviewStatus.playing => l10n.searchPreviewStop,
      },
      icon: switch (status) {
        PreviewStatus.idle => AppIcons.headphones,
        PreviewStatus.loading => AppIcons.hourglassTop,
        PreviewStatus.playing => AppIcons.pause,
      },
      variant: PillVariant.tonal,
      busy: status == PreviewStatus.loading,
      onPressed: () => togglePreview(context, hit),
    );
  }
}

/// 검색 결과 줄 오른쪽의 미리 듣기 버튼 (면 없는 작은 아이콘 버튼).
/// 누르면 미리 듣고, 준비 중이거나 듣는 중이면 강조 색으로 바뀌어 누를 때 멈춘다.
class PreviewRowButton extends StatelessWidget {
  const PreviewRowButton({super.key, required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = context.select(
      (PreviewCubit c) =>
          c.state.isActive(hit.id) ? c.state.status : PreviewStatus.idle,
    );
    return RowIconButton(
      key: const ValueKey('preview-row-button'),
      icon: switch (status) {
        PreviewStatus.idle => AppIcons.headphones,
        PreviewStatus.loading => AppIcons.hourglassTop,
        PreviewStatus.playing => AppIcons.pause,
      },
      tooltip: switch (status) {
        PreviewStatus.idle => l10n.searchPreview,
        PreviewStatus.loading => l10n.searchPreviewLoading,
        PreviewStatus.playing => l10n.searchPreviewStop,
      },
      accent: status != PreviewStatus.idle,
      busy: status == PreviewStatus.loading,
      onPressed: () => togglePreview(context, hit),
    );
  }
}

/// 미리 듣는 곡의 재생 진행도: 얼마나 들었는지 막대 + 시간.
/// 이 곡을 듣고 있지 않으면 아무것도 그리지 않는다. [showTime]이면 막대 아래에 시간도 보인다.
class PreviewProgressBar extends StatelessWidget {
  const PreviewProgressBar({
    super.key,
    required this.hitId,
    this.showTime = false,
  });

  final String hitId;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final state = context.select(
      (PreviewCubit c) => c.state.isActive(hitId) ? c.state : null,
    );
    if (state == null || state.status != PreviewStatus.playing) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme.bodySmall;
    final progress = state.progress;
    final duration = progress?.duration;
    return Column(
      key: const ValueKey('preview-progress'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressLine(value: state.fraction),
        if (showTime) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${formatDuration(progress?.position ?? Duration.zero)}'
            ' / ${duration == null ? '--:--' : formatDuration(duration)}',
            style: text,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

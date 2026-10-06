import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == EngineFailure.unavailable
              ? l10n.searchPreviewUnavailable
              : l10n.searchPreviewFailed,
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
      onPressed: () => togglePreview(context, hit),
    );
  }
}

/// 검색 결과 줄 오른쪽: 이 곡을 미리 듣는 중(또는 준비 중)일 때만 보이는 멈춤 버튼.
class PreviewIndicator extends StatelessWidget {
  const PreviewIndicator({super.key, required this.hitId});

  final String hitId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = context.select(
      (PreviewCubit c) =>
          c.state.isActive(hitId) ? c.state.status : PreviewStatus.idle,
    );
    if (status == PreviewStatus.idle) return const SizedBox.shrink();
    final loading = status == PreviewStatus.loading;
    return CircleIconButton(
      key: const ValueKey('preview-indicator'),
      icon: loading ? AppIcons.hourglassTop : AppIcons.pause,
      tooltip: loading ? l10n.searchPreviewLoading : l10n.searchPreviewStop,
      emphasized: !loading,
      onPressed: context.read<PreviewCubit>().stop,
    );
  }
}

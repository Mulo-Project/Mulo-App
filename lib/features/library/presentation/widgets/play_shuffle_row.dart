import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/track.dart';

/// 앨범 · 아티스트 · 장르 · 재생목록 상세에서 쓰는 재생 + 셔플 버튼 한 줄.
/// [tracks]가 비어 있으면 둘 다 눌리지 않는다.
class PlayShuffleRow extends StatelessWidget {
  const PlayShuffleRow({super.key, required this.tracks, this.playLabel});

  final List<Track> tracks;

  /// 재생 버튼 글자 (기본은 "재생").
  final String? playLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.read<NowPlayingCubit>();
    final empty = tracks.isEmpty;
    return Padding(
      padding: AppSpacing.screen,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          PillButton(
            label: playLabel ?? l10n.actionPlay,
            icon: AppIcons.play,
            onPressed: empty ? null : () => now.playQueue(tracks),
          ),
          PillButton(
            label: l10n.actionShuffle,
            icon: AppIcons.shuffle,
            variant: PillVariant.tonal,
            onPressed: empty ? null : () => now.playShuffled(tracks),
          ),
        ],
      ),
    );
  }
}

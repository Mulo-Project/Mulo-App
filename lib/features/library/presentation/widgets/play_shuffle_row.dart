import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/track.dart';

/// 앨범 · 아티스트 · 장르 · 재생목록 상세에서 쓰는 재생 + 셔플 버튼 한 줄.
/// [tracks]가 비어 있으면 둘 다 눌리지 않는다.
class PlayShuffleRow extends StatelessWidget {
  const PlayShuffleRow({
    super.key,
    required this.tracks,
    this.playLabel,
    this.extra,
  });

  final List<Track> tracks;

  /// 재생 버튼 글자 (기본은 "재생").
  final String? playLabel;

  /// 셔플 옆에 더 놓을 버튼 (재생목록 상세의 "곡 추가" 등).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.read<NowPlayingCubit>();
    final empty = tracks.isEmpty;
    final play = PillButton(
      label: playLabel ?? l10n.actionPlay,
      icon: AppIcons.play,
      compact: extra != null,
      onPressed: empty ? null : () => now.playQueue(tracks),
    );
    final shuffle = PillButton(
      label: l10n.actionShuffle,
      icon: AppIcons.shuffle,
      variant: PillVariant.tonal,
      compact: extra != null,
      onPressed: empty ? null : () => now.playShuffled(tracks),
    );
    return Padding(
      padding: AppSpacing.screen,
      // 버튼이 셋이면 줄이 바뀌지 않게 한 줄에 같은 너비로 나눈다.
      child: extra == null
          ? Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [play, shuffle],
            )
          : Row(
              children: [
                Expanded(child: play),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: shuffle),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: extra!),
              ],
            ),
    );
  }
}

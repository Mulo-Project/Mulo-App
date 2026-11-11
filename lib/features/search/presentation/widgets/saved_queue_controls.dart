import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../player/presentation/widgets/player_common.dart';

/// 임시 저장한 곡 상세 화면 아래의 고정 조작부. 메인 플레이어의 조작부([PlayerControls])를 그대로 쓰고,
/// 파일 곡에서만 되는 가사 싱크 · 좋아요는 뺀다 (진행 막대 → 10초 · 이전 · 재생 · 다음 → 셔플 · 반복 · 구간 · 수면 · 이퀄라이저 · 대기열).
class SavedQueueControls extends StatelessWidget {
  const SavedQueueControls({super.key, this.onStart});

  /// 임시 저장 곡을 아직 안 틀었을 때(상세를 그냥 열었을 때)의 시작 동작. 있으면 재생 버튼이 이걸 부른다.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: BlocBuilder<NowPlayingCubit, NowPlayingState>(
          builder: (context, state) {
            final idle = onStart != null;
            final data = PlayerLayoutData(
              track: state.track ?? _placeholder,
              state: state,
              vm: context.read<NowPlayingCubit>(),
              showLyrics: false,
              onToggleLyrics: () {},
            );
            return PlayerControls(
              data: data,
              savedMode: true,
              play: SolidPlayButton(
                key: const ValueKey('queue-bar-play'),
                data: data,
                onPressed: idle ? onStart : null,
                playing: idle ? false : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

final _placeholder = Track(
  id: '',
  title: '',
  artist: '',
  album: '',
  duration: Duration.zero,
  addedAt: DateTime.fromMillisecondsSinceEpoch(0),
);

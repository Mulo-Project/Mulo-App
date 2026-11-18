import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/lyrics_cubit.dart';
import '../bloc/lyrics_settings_cubit.dart';

/// 영상 하단에 싱크 가사의 현재 줄을 보여 준다 (유튜브 자막처럼). 영상 옵션의 "가사 표시"가 켜져 있고,
/// 지금 곡에 싱크 가사가 있을 때만 보인다. 터치는 영상 컨트롤로 그대로 넘어간다.
class VideoLyricsLine extends StatelessWidget {
  const VideoLyricsLine({super.key});

  @override
  Widget build(BuildContext context) {
    final on = context.select((LyricsSettingsCubit c) => c.state.videoLyrics);
    if (!on) return const SizedBox.shrink();
    return const _VideoLyricsBody();
  }
}

class _VideoLyricsBody extends StatefulWidget {
  const _VideoLyricsBody();

  @override
  State<_VideoLyricsBody> createState() => _VideoLyricsBodyState();
}

class _VideoLyricsBodyState extends State<_VideoLyricsBody> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final track = context.read<NowPlayingCubit>().state.track;
    if (track != null) context.read<LyricsCubit>().show(track);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NowPlayingCubit, NowPlayingState>(
      // 곡이 바뀌면 새 곡의 가사를 불러온다.
      listenWhen: (a, b) => a.track?.id != b.track?.id,
      listener: (context, _) => _load(),
      child: Builder(
        builder: (context) {
          final track = context.select((NowPlayingCubit c) => c.state.track);
          final position = context.select(
            (NowPlayingCubit c) => c.state.position,
          );
          final state = context.watch<LyricsCubit>().state;
          if (track == null || state.trackId != track.id) {
            return const SizedBox.shrink();
          }
          return VideoLyricsText(lyrics: state.lyrics, position: position);
        },
      ),
    );
  }
}

/// [lyrics]의 [position] 줄을 영상 하단에 그린다. 싱크 가사가 아니거나 줄이 없으면 아무것도 안 그린다.
class VideoLyricsText extends StatelessWidget {
  const VideoLyricsText({
    super.key,
    required this.lyrics,
    required this.position,
  });

  final Lyrics? lyrics;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final lyrics = this.lyrics;
    if (lyrics == null || !lyrics.isSynced) return const SizedBox.shrink();
    final index = lyrics.currentLine(position);
    if (index < 0) return const SizedBox.shrink();
    // 같은 시간으로 묶인 줄은 한 덩어리로 보여 준다.
    final (first, last) = lyrics.groupAt(index);
    final line = [
      for (var i = first; i <= last; i++) lyrics.lines[i].text,
    ].where((t) => t.trim().isNotEmpty).join('\n');
    if (line.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          // 아래 재생 막대(시간 · 진행선)와 겹치지 않게 띄운다.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xl + AppSpacing.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.scrim.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: text.titleSmall?.copyWith(color: AppPalette.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

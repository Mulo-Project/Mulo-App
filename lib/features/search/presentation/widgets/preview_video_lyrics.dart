import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../lyrics/domain/entities/lyrics.dart';
import '../../../lyrics/presentation/bloc/lyrics_settings_cubit.dart';
import '../../../lyrics/presentation/widgets/video_lyrics_line.dart';
import '../../domain/usecases/search_usecases.dart';
import '../bloc/preview_cubit.dart';

/// 미리 듣는 영상 하단에 유튜브 자막을 가사처럼 보여 준다 ("가사 표시"가 켜져 있을 때만 자막을 읽어 온다).
/// 자막이 없거나 읽지 못하면 아무것도 보이지 않는다.
class PreviewVideoLyrics extends StatelessWidget {
  const PreviewVideoLyrics({super.key});

  @override
  Widget build(BuildContext context) {
    final on = context.select((LyricsSettingsCubit c) => c.state.videoLyrics);
    if (!on) return const SizedBox.shrink();
    final url = context.select((PreviewCubit c) => c.state.hit?.url);
    if (url == null || !sl.isRegistered<FetchSubtitles>()) {
      return const SizedBox.shrink();
    }
    return _Loaded(key: ValueKey(url), url: url);
  }
}

class _Loaded extends StatefulWidget {
  const _Loaded({super.key, required this.url});

  final String url;

  @override
  State<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends State<_Loaded> {
  Lyrics? _lyrics;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final track = await sl<FetchSubtitles>()(FetchSubtitlesParams(widget.url));
      if (!mounted || track == null) return;
      final lyrics = Lyrics.parse(track.withoutSoundCues().toLrc());
      if (mounted) setState(() => _lyrics = lyrics);
    } catch (_) {
      // 자막을 못 읽어도 영상 재생에는 영향이 없다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = context.select(
      (PreviewCubit c) => c.state.progress?.position ?? Duration.zero,
    );
    return VideoLyricsText(lyrics: _lyrics, position: position);
  }
}

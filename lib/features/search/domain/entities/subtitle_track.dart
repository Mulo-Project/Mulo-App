import 'package:equatable/equatable.dart';

/// 자막의 한 줄: [start]부터 [text]를 보여 준다.
class SubtitleCue extends Equatable {
  const SubtitleCue(this.start, this.text);

  final Duration start;
  final String text;

  @override
  List<Object?> get props => [start, text];
}

/// 영상 하나의 자막 한 벌 (언어 하나). 가사로 가져올 때 쓴다.
class SubtitleTrack extends Equatable {
  const SubtitleTrack({
    required this.language,
    required this.cues,
    this.automatic = false,
  });

  /// 언어 코드 (`ko`, `en` …).
  final String language;

  /// 자동 생성 자막인지 (사람이 단 자막보다 틀릴 수 있다).
  final bool automatic;
  final List<SubtitleCue> cues;

  /// 효과음 · 음악 표시 줄(`[음악]`, `(박수)`, `♪`)을 뺀 사본.
  SubtitleTrack withoutSoundCues() => SubtitleTrack(
    language: language,
    automatic: automatic,
    cues: [
      for (final c in cues)
        if (!_isSoundCue(c.text)) c,
    ],
  );

  /// 시간 순으로 `[mm:ss.xx]글` 한 줄씩 적은 .lrc 글. 빈 줄은 건너뛴다.
  String toLrc() {
    final b = StringBuffer();
    for (final c in cues) {
      final text = c.text.trim();
      if (text.isEmpty) continue;
      final ms = c.start.inMilliseconds;
      final mm = (ms ~/ 60000).toString().padLeft(2, '0');
      final ss = ((ms ~/ 1000) % 60).toString().padLeft(2, '0');
      final cs = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
      b.writeln('[$mm:$ss.$cs]$text');
    }
    return b.toString().trimRight();
  }

  @override
  List<Object?> get props => [language, automatic, cues];
}

final _soundOnly = RegExp(r'^[\s♪♫♬♩\-–]*$');
final _soundTag = RegExp(r'^[\[\(（【][^\]\)）】]*[\]\)）】]$');

/// 글 전체가 `[Music]` · `(박수)` · `♪` 같은 효과음 표시인 줄.
bool _isSoundCue(String text) {
  final t = text.trim();
  return _soundOnly.hasMatch(t) || _soundTag.hasMatch(t);
}

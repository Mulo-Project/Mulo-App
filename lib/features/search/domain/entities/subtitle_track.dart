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

/// 자막 파일(WebVTT)을 읽는다. 자동 자막은 앞 줄을 되풀이하며 이어지므로,
/// 바로 앞 칸에 이미 나온 줄은 빼고 새로 생긴 줄만 남긴다. 태그(`<c>` · `<00:01.0>`)는 지운다.
List<SubtitleCue> parseVtt(String vtt) {
  final cues = <SubtitleCue>[];
  var prev = <String>[];
  final blocks = vtt.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
  final time = RegExp(r'(?:(\d+):)?(\d{1,2}):(\d{2})[.,](\d{1,3})\s*-->');
  for (final block in blocks) {
    final lines = block.split('\n');
    final i = lines.indexWhere(time.hasMatch);
    if (i < 0) continue;
    final m = time.firstMatch(lines[i])!;
    final start = Duration(
      hours: int.parse(m.group(1) ?? '0'),
      minutes: int.parse(m.group(2)!),
      seconds: int.parse(m.group(3)!),
      milliseconds: int.parse(m.group(4)!.padRight(3, '0')),
    );
    final text = <String>[
      for (final l in lines.skip(i + 1))
        if (_clean(l).isNotEmpty) _clean(l),
    ];
    final fresh = [
      for (final l in text)
        if (!prev.contains(l)) l,
    ];
    prev = text;
    if (fresh.isEmpty) continue;
    cues.add(SubtitleCue(start, fresh.join(' ')));
  }
  return cues;
}

String _clean(String line) => line
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .trim();

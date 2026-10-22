import 'package:equatable/equatable.dart';

/// 재생 화면 가사 보기 모양.
enum LyricsTheme {
  /// 가사가 쭉 이어지고 현재 줄만 크게 강조된다.
  list,

  /// 현재 줄이 가운데에 크게 고정되고 앞뒤 몇 줄만 흐리게 보인다.
  centered,
}

/// 가사 · 싱크 관련 사용자 설정.
class LyricsSettings extends Equatable {
  const LyricsSettings({
    this.latencyMs = defaultLatencyMs,
    this.theme = LyricsTheme.list,
    this.coverBackground = false,
    this.overlay = false,
  });

  /// 지금을 누를 때 반응 시간만큼 앞당겨 찍는 기본값 (밀리초).
  static const defaultLatencyMs = 200;
  static const maxLatencyMs = 500;

  /// 지금을 누른 시간에서 앞당길 시간 (밀리초). 0 ~ [maxLatencyMs].
  final int latencyMs;
  final LyricsTheme theme;

  /// 테마와 따로, 앨범 커버를 옅게 뒤에 까는가.
  final bool coverBackground;

  /// 앱을 벗어나도 다른 앱 위에 지금 줄을 띄운다 (Android, 싱크 가사가 있는 곡).
  final bool overlay;

  Duration get latency => Duration(milliseconds: latencyMs);

  LyricsSettings copyWith({
    int? latencyMs,
    LyricsTheme? theme,
    bool? coverBackground,
    bool? overlay,
  }) => LyricsSettings(
    latencyMs: (latencyMs ?? this.latencyMs).clamp(0, maxLatencyMs),
    theme: theme ?? this.theme,
    coverBackground: coverBackground ?? this.coverBackground,
    overlay: overlay ?? this.overlay,
  );

  @override
  List<Object?> get props => [latencyMs, theme, coverBackground, overlay];
}

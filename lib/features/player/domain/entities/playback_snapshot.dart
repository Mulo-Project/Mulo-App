import 'package:equatable/equatable.dart';

import 'player_repeat_mode.dart';

/// 엔진에 넘기는 곡 하나. 알림 · 잠금화면은 앱이 꺼져 있어도 이 정보로 그려진다.
class PlaybackItem extends Equatable {
  const PlaybackItem({
    required this.id,
    required this.uri,
    required this.title,
    this.artist = '',
    this.album = '',
    this.duration = Duration.zero,
  });

  final String id;
  final String uri;
  final String title;
  final String artist;
  final String album;
  final Duration duration;

  @override
  List<Object?> get props => [id, uri, title, artist, album, duration];
}

/// 대기열 스냅샷: 앱(Dart)이 정한 순서의 목록 · 현재 위치 · 반복 모드.
/// 곡을 넘기는 일은 엔진이 맡고, 순서를 정하는 규칙(셔플 · 다음에 재생 · 이동 · 삭제)은 앱이 쥔다.
class PlaybackSnapshot extends Equatable {
  const PlaybackSnapshot({
    required this.items,
    required this.index,
    required this.playing,
    this.repeat = PlayerRepeatMode.off,
    this.position,
    this.extras = '',
  });

  final List<PlaybackItem> items;
  final int index;
  final bool playing;
  final PlayerRepeatMode repeat;

  /// 현재 곡에서 시작할 위치. null이면 엔진의 현재 위치를 그대로 둔다
  /// (같은 곡을 계속 듣는 중에 뒤의 목록만 바뀐 경우).
  final Duration? position;

  /// 앱만 해석하는 문자열 (셔플 여부 · 섞기 전 순서). 엔진은 그대로 보관했다가 돌려준다.
  final String extras;

  PlaybackItem? get current =>
      index >= 0 && index < items.length ? items[index] : null;

  @override
  List<Object?> get props => [items, index, playing, repeat, position, extras];
}

/// 엔진이 스스로 곡을 넘겼다는 알림 (자동 · 알림 · 이어폰).
class PlaybackTrackChange extends Equatable {
  const PlaybackTrackChange(this.index, this.id);

  final int index;
  final String id;

  @override
  List<Object?> get props => [index, id];
}

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
    this.videoUri = '',
  });

  final String id;
  final String uri;
  final String title;
  final String artist;
  final String album;
  final Duration duration;

  /// 영상 전용 주소 (임시 저장한 영상 곡). 있으면 네이티브가 소리와 합쳐 한 시계로 튼다.
  final String videoUri;

  @override
  List<Object?> get props => [
    id,
    uri,
    title,
    artist,
    album,
    duration,
    videoUri,
  ];
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
    this.shuffleNew = false,
  });

  final List<PlaybackItem> items;
  final int index;
  final bool playing;
  final PlayerRepeatMode repeat;

  /// 현재 곡에서 시작할 위치. null이면 엔진의 현재 위치를 그대로 둔다
  /// (같은 곡을 계속 듣는 중에 뒤의 목록만 바뀐 경우).
  final Duration? position;

  /// 엔진이 쥐는 문자열 (셔플 여부 · 섞기 전 순서). 비어 있으면 엔진이 지금 것을 그대로 둔다.
  /// 셔플과 섞기 전 순서는 엔진이 정하므로 앱은 [restore]로 돌려받은 값을 읽기만 한다.
  final String extras;

  /// true면 [items]는 섞기 전 순서이고, 엔진이 [index]번 곡을 맨 앞에 두고 나머지를 섞어 셔플로 시작한다.
  /// 섞인 순서는 [AudioPlayerRepository.watchQueue]로 돌아온다.
  final bool shuffleNew;

  PlaybackItem? get current =>
      index >= 0 && index < items.length ? items[index] : null;

  @override
  List<Object?> get props => [
    items,
    index,
    playing,
    repeat,
    position,
    extras,
    shuffleNew,
  ];
}

/// 엔진이 스스로 곡을 넘겼다는 알림 (자동 · 알림 · 이어폰).
class PlaybackTrackChange extends Equatable {
  const PlaybackTrackChange(this.index, this.id);

  final int index;
  final String id;

  @override
  List<Object?> get props => [index, id];
}

/// 엔진이 쥔 대기열의 지금 모습 (셔플 · 한 바퀴 뒤 재셔플 · 반복 변경 뒤에 온다).
/// 앱은 이것을 비추기만 한다: [ids]는 엔진 대기열의 곡 id 순서이고 [index]는 지금 곡 자리다.
class PlaybackQueueChange extends Equatable {
  const PlaybackQueueChange({
    required this.ids,
    required this.index,
    required this.shuffle,
    required this.repeat,
  });

  final List<String> ids;
  final int index;
  final bool shuffle;
  final PlayerRepeatMode repeat;

  @override
  List<Object?> get props => [ids, index, shuffle, repeat];
}

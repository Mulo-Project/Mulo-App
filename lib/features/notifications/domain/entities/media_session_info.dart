import 'package:equatable/equatable.dart';

/// 재생 알림 · 잠금화면에 보여 줄 지금 재생 상태 (이미 숨김 설정이 반영된 글자).
class MediaSessionInfo extends Equatable {
  const MediaSessionInfo({
    required this.title,
    required this.artist,
    required this.duration,
    required this.position,
    required this.playing,
    this.album = '',
    this.artUri,
    this.hasPrevious = true,
    this.hasNext = true,
  });

  final String title;
  final String artist;
  final String album;

  /// 커버 주소 (http · https · file). 없으면 null.
  final String? artUri;
  final Duration duration;
  final Duration position;
  final bool playing;
  final bool hasPrevious;
  final bool hasNext;

  @override
  List<Object?> get props => [
    title,
    artist,
    album,
    artUri,
    duration,
    position,
    playing,
    hasPrevious,
    hasNext,
  ];
}

enum MediaCommandType { play, pause, next, previous, seek, stop }

/// 알림 · 잠금화면 · 이어폰 버튼에서 온 조작.
class MediaCommand extends Equatable {
  const MediaCommand(this.type, [this.position]);

  final MediaCommandType type;

  /// [MediaCommandType.seek]일 때 옮길 자리.
  final Duration? position;

  @override
  List<Object?> get props => [type, position];
}

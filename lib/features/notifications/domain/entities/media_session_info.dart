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
    this.favorite = false,
    this.preview = false,
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

  /// 지금 곡이 좋아요(즐겨찾기)에 들어 있는지 (알림의 하트 모양).
  final bool favorite;

  /// 검색 결과 미리 듣기인지 (재생 알림을 잠시 빌려 쓴다. 이전 · 다음 · 좋아요는 없다).
  final bool preview;

  /// 커버 주소만 바꾼 사본.
  MediaSessionInfo withArtUri(String? uri) => MediaSessionInfo(
    title: title,
    artist: artist,
    album: album,
    artUri: uri,
    duration: duration,
    position: position,
    playing: playing,
    hasPrevious: hasPrevious,
    hasNext: hasNext,
    favorite: favorite,
    preview: preview,
  );

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
    favorite,
    preview,
  ];
}

enum MediaCommandType { play, pause, next, previous, seek, stop, favorite }

/// 재생 알림에 잠시 보여 줄 미리 듣기 (소리가 나는 동안만 만든다).
class PreviewNotice extends Equatable {
  const PreviewNotice({
    required this.title,
    required this.uploader,
    required this.position,
    this.duration,
    this.artUri,
  });

  final String title;
  final String uploader;
  final String? artUri;
  final Duration position;
  final Duration? duration;

  @override
  List<Object?> get props => [title, uploader, artUri, position, duration];
}

/// 알림 · 잠금화면 · 이어폰 버튼에서 온 조작.
class MediaCommand extends Equatable {
  const MediaCommand(this.type, [this.position]);

  final MediaCommandType type;

  /// [MediaCommandType.seek]일 때 옮길 자리.
  final Duration? position;

  @override
  List<Object?> get props => [type, position];
}

import 'package:flutter/foundation.dart';

/// 보관함의 곡 한 개. 지금은 자리 표시용이고, 저장소(drift)가 생기면 여기에 필드를 맞춘다.
@immutable
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.addedOrder,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;

  /// 추가된 순서 (클수록 최근). 추가일 정렬용.
  final int addedOrder;

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// `3:42`, `1:02:05` 형식.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

import 'package:equatable/equatable.dart';

import 'media_info.dart';

/// 플레이어가 지금 내고 있는 미리 듣기 (앱이 다시 켜졌을 때 화면 상태를 맞추는 데 쓴다).
class PreviewSnapshot extends Equatable {
  const PreviewSnapshot({
    required this.hit,
    required this.position,
    this.duration,
    this.paused = false,
  });

  /// 듣고 있는 곡. 앱이 꺼졌다 켜져도 알 수 있게 플레이어가 기억해 둔 것이다.
  final MediaHit hit;
  final Duration position;
  final Duration? duration;
  final bool paused;

  @override
  List<Object?> get props => [hit, position, duration, paused];
}

import 'package:equatable/equatable.dart';

/// 미리 듣기가 어디까지 재생됐는지. [duration]은 아직 모르면 null.
/// [buffered]는 어디까지 미리 받아 두었는지 (유튜브처럼 막대에 연하게 보인다).
class PreviewProgress extends Equatable {
  const PreviewProgress({
    required this.position,
    this.duration,
    this.buffered = Duration.zero,
  });

  final Duration position;
  final Duration? duration;
  final Duration buffered;

  @override
  List<Object?> get props => [position, duration, buffered];
}

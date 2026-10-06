import 'package:equatable/equatable.dart';

/// 미리 듣기가 어디까지 재생됐는지. [duration]은 아직 모르면 null.
class PreviewProgress extends Equatable {
  const PreviewProgress({required this.position, this.duration});

  final Duration position;
  final Duration? duration;

  @override
  List<Object?> get props => [position, duration];
}

import 'package:equatable/equatable.dart';

/// 소리가 나가는 기기의 종류.
enum AudioOutputKind { speaker, wired, bluetooth, usb, other }

/// 지금 소리가 나가는 출력 기기.
class AudioOutput extends Equatable {
  const AudioOutput({required this.kind, this.name = ''});

  final AudioOutputKind kind;

  /// 기기가 알려 준 이름 (블루투스 이어폰 이름 등). 없으면 빈 문자열.
  final String name;

  @override
  List<Object?> get props => [kind, name];
}

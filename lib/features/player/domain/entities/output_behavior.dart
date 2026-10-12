import 'package:equatable/equatable.dart';

/// 출력 기기(블루투스 · 이어폰)가 바뀔 때의 재생 동작 설정.
class OutputBehavior extends Equatable {
  const OutputBehavior({
    this.pauseOnDisconnect = true,
    this.resumeOnConnect = false,
  });

  /// 이어폰이 빠지거나 블루투스 연결이 끊기면 재생을 멈춘다.
  final bool pauseOnDisconnect;

  /// 기기가 다시 연결되면 (끊겨서 멈춘 재생을) 이어서 재생한다.
  final bool resumeOnConnect;

  OutputBehavior copyWith({bool? pauseOnDisconnect, bool? resumeOnConnect}) =>
      OutputBehavior(
        pauseOnDisconnect: pauseOnDisconnect ?? this.pauseOnDisconnect,
        resumeOnConnect: resumeOnConnect ?? this.resumeOnConnect,
      );

  @override
  List<Object?> get props => [pauseOnDisconnect, resumeOnConnect];
}

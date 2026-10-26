import 'package:equatable/equatable.dart';

/// 이 기기의 yt-dlp 상태.
class EngineStatus extends Equatable {
  const EngineStatus({
    this.supported = true,
    this.installed = false,
    this.version,
    this.managed = false,
    this.removable = false,
    this.revertible = false,
  });

  /// 앱이 이 기기에 yt-dlp를 설치할 수 있는지 (데스크톱만).
  final bool supported;

  /// 쓸 수 있는 yt-dlp가 있는지 (앱이 받은 것 또는 PATH의 것).
  final bool installed;
  final String? version;

  /// 앱이 받아 둔 yt-dlp인지 (false면 PATH의 것).
  final bool managed;

  /// 앱이 받아 둔 yt-dlp를 지울 수 있는지 (데스크톱에서 앱이 받은 파일이 있을 때만).
  /// PATH의 yt-dlp나 Android의 내장 yt-dlp는 지우지 않는다.
  final bool removable;

  /// 업데이트로 받은 yt-dlp를 앱에 들어 있는 버전으로 되돌릴 수 있는지
  /// (Android full에서 업데이트한 적이 있을 때만).
  final bool revertible;

  @override
  List<Object?> get props => [
    supported,
    installed,
    version,
    managed,
    removable,
    revertible,
  ];
}

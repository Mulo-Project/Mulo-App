import 'package:equatable/equatable.dart';

/// 이 기기의 yt-dlp 상태.
class EngineStatus extends Equatable {
  const EngineStatus({
    this.supported = true,
    this.installed = false,
    this.version,
    this.managed = false,
  });

  /// 앱이 이 기기에 yt-dlp를 설치할 수 있는지 (Android full만).
  final bool supported;

  /// 쓸 수 있는 yt-dlp가 있는지 (앱이 받은 것 또는 PATH의 것).
  final bool installed;
  final String? version;

  /// 앱이 받아 둔 yt-dlp인지 (false면 PATH의 것).
  final bool managed;

  @override
  List<Object?> get props => [
    supported,
    installed,
    version,
    managed,
  ];
}

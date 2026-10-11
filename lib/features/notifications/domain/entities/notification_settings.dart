import 'package:equatable/equatable.dart';

/// 알림 설정 (상세 기능: 알림 곡 정보 숨기기 #32 + 받기 · 재생 알림 켜고 끄기).
class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.downloadProgress = true,
    this.downloadResult = true,
    this.playback = true,
    this.hideSongInfo = false,
    this.backgroundDownload = true,
  });

  /// 받는 동안 진행 알림.
  final bool downloadProgress;

  /// 받기가 끝나거나 실패했을 때 알림.
  final bool downloadResult;

  /// 재생 알림 (알림창 · 잠금화면 조작).
  final bool playback;

  /// 켜면 알림 · 잠금화면에 제목 · 아티스트 · 커버를 보이지 않는다.
  final bool hideSongInfo;

  /// 켜면 앱이 뒤로 가거나 닫혀도 받기가 이어지게 포그라운드 서비스로 붙들어 둔다.
  /// 끄면 앱이 화면에 있는 동안에만 받는다 (알림은 진행 알림 설정을 따른다).
  final bool backgroundDownload;

  NotificationSettings copyWith({
    bool? downloadProgress,
    bool? downloadResult,
    bool? playback,
    bool? hideSongInfo,
    bool? backgroundDownload,
  }) => NotificationSettings(
    downloadProgress: downloadProgress ?? this.downloadProgress,
    downloadResult: downloadResult ?? this.downloadResult,
    playback: playback ?? this.playback,
    hideSongInfo: hideSongInfo ?? this.hideSongInfo,
    backgroundDownload: backgroundDownload ?? this.backgroundDownload,
  );

  @override
  List<Object?> get props => [
    downloadProgress,
    downloadResult,
    playback,
    hideSongInfo,
    backgroundDownload,
  ];
}

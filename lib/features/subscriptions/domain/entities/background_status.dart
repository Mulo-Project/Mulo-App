import 'package:equatable/equatable.dart';

/// 백그라운드 새 영상 확인의 진단 정보 (설정 화면에서 "왜 알림이 안 오는지" 보이려고).
class BackgroundStatus extends Equatable {
  const BackgroundStatus({
    this.scheduled = false,
    this.notificationsBlocked = false,
    this.lastRunAt,
    this.channels = 0,
    this.failedChannels = 0,
    this.notified = 0,
    this.blocked = false,
  });

  /// 주기 확인이 예약돼 있는지.
  final bool scheduled;

  /// 알림 권한 · 앱 알림 · 새 영상 알림 채널 중 하나가 꺼져 있는지.
  final bool notificationsBlocked;

  /// 마지막으로 확인한 시각 (한 번도 안 했으면 null).
  final DateTime? lastRunAt;

  /// 마지막 확인에서 본 채널 수와 읽지 못한 채널 수.
  final int channels;
  final int failedChannels;

  /// 마지막 확인에서 알린 새 영상 수.
  final int notified;

  /// 마지막 확인에서 새 영상이 있었지만 알림이 막혀 알리지 못했는지.
  final bool blocked;

  @override
  List<Object?> get props => [
    scheduled,
    notificationsBlocked,
    lastRunAt,
    channels,
    failedChannels,
    notified,
    blocked,
  ];
}

import 'package:equatable/equatable.dart';

/// 알림 설정 (상세 기능: 알림 곡 정보 숨기기 #32 + 재생 알림 켜고 끄기).
class NotificationSettings extends Equatable {
  const NotificationSettings({this.playback = true, this.hideSongInfo = false});

  /// 재생 알림 (알림창 · 잠금화면 조작).
  final bool playback;

  /// 켜면 알림 · 잠금화면에 제목 · 아티스트 · 커버를 보이지 않는다.
  final bool hideSongInfo;

  NotificationSettings copyWith({bool? playback, bool? hideSongInfo}) =>
      NotificationSettings(
        playback: playback ?? this.playback,
        hideSongInfo: hideSongInfo ?? this.hideSongInfo,
      );

  @override
  List<Object?> get props => [playback, hideSongInfo];
}

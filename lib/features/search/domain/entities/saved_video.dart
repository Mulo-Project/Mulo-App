import 'package:equatable/equatable.dart';

import 'media_info.dart';
import 'video_quality.dart';

/// 사용자가 저장해 둔 스트리밍 음원(유튜브는 영상) 하나. 소리 · 영상 데이터를 앱 안에 받아 두어 바로 듣는다.
class SavedVideo extends Equatable {
  const SavedVideo({
    required this.hit,
    this.streamId,
    this.ready = false,
    this.quality,
  });

  final MediaHit hit;

  /// 네이티브가 보관 여부를 가르는 스트림 id (영상 id와 다르다). 모르면 null.
  final String? streamId;

  /// 데이터를 끝까지 받아 두었다 (false면 받는 중이거나 실패해서 일부만 있다).
  final bool ready;

  /// 저장할 때 고른 영상 화질 (영상이 아닌 음원은 null). 들을 때도 이 화질로 읽어야 저장한 데이터를 쓴다.
  final VideoQuality? quality;

  String get id => hit.id;

  SavedVideo copyWith({String? streamId, bool? ready}) => SavedVideo(
    hit: hit,
    streamId: streamId ?? this.streamId,
    ready: ready ?? this.ready,
    quality: quality,
  );

  @override
  List<Object?> get props => [hit, streamId, ready, quality];
}

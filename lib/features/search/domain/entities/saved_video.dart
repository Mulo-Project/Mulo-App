import 'package:equatable/equatable.dart';

import 'media_info.dart';
import 'video_quality.dart';
import 'video_stream.dart';

/// 사용자가 저장해 둔 스트리밍 음원(유튜브는 영상) 하나. 소리 · 영상 데이터를 앱 안에 받아 두어 바로 듣는다.
class SavedVideo extends Equatable {
  const SavedVideo({
    required this.hit,
    this.streamId,
    this.ready = false,
    this.quality,
    this.sources = const [],
  });

  final MediaHit hit;

  /// 네이티브가 보관 여부를 가르는 스트림 id (영상 id와 다르다). 모르면 null.
  final String? streamId;

  /// 데이터를 끝까지 받아 두었다 (false면 받는 중이거나 실패해서 일부만 있다).
  final bool ready;

  /// 저장할 때 고른 영상 화질 (영상이 아닌 음원은 null). 들을 때도 이 화질로 읽어야 저장한 데이터를 쓴다.
  final VideoQuality? quality;

  /// 저장할 때 받은 주소들 (영상 전용 + 소리 전용이면 둘, 아니면 하나). 받기가 끝난 곡은 이 주소로 요청해도
  /// 데이터를 폰의 저장소에서 바로 읽으므로 주소가 만료돼도 · 오프라인에서도 링크를 다시 풀지 않고 튼다.
  final List<VideoStream> sources;

  /// 저장해 둔 영상(소리 포함 한 줄 또는 영상 전용). 영상 없이 소리만 저장했으면 null.
  VideoStream? get videoSource => sources.length >= 2
      ? sources.first
      : (sources.length == 1 && sources.first.muxed ? sources.first : null);

  /// 저장해 둔 소리 (소리 포함 영상이면 그 한 줄). 없으면 null.
  VideoStream? get audioSource => sources.isEmpty ? null : sources.last;

  String get id => hit.id;

  SavedVideo copyWith({String? streamId, bool? ready}) => SavedVideo(
    hit: hit,
    streamId: streamId ?? this.streamId,
    ready: ready ?? this.ready,
    quality: quality,
    sources: sources,
  );

  @override
  List<Object?> get props => [hit, streamId, ready, quality, sources];
}

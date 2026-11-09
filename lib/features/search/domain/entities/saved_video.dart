import 'package:equatable/equatable.dart';

import 'media_info.dart';

/// 사용자가 보관해 둔 스트리밍 영상 하나. 소리 · 영상 데이터를 앱 안에 받아 두어 바로 듣는다.
class SavedVideo extends Equatable {
  const SavedVideo({required this.hit, this.streamId, this.ready = false});

  final MediaHit hit;

  /// 네이티브가 보관 여부를 가르는 스트림 id (영상 id와 다르다). 모르면 null.
  final String? streamId;

  /// 데이터를 끝까지 받아 두었다 (false면 받는 중이거나 실패해서 일부만 있다).
  final bool ready;

  String get id => hit.id;

  SavedVideo copyWith({String? streamId, bool? ready}) => SavedVideo(
    hit: hit,
    streamId: streamId ?? this.streamId,
    ready: ready ?? this.ready,
  );

  @override
  List<Object?> get props => [hit, streamId, ready];
}

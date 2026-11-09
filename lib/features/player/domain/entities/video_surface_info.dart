import 'package:equatable/equatable.dart';

/// 네이티브가 내보내는 영상 화면(텍스처)의 지금 상태.
class VideoSurfaceInfo extends Equatable {
  const VideoSurfaceInfo({
    required this.textureId,
    this.ready = false,
    this.width = 0,
    this.height = 0,
  });

  final int textureId;

  /// 첫 화면이 그려졌다.
  final bool ready;

  /// 영상 크기(픽셀). 아직 모르면 0.
  final int width;
  final int height;

  @override
  List<Object?> get props => [textureId, ready, width, height];
}

/// 영상 화면의 바뀐 부분. 바뀌지 않은 값은 null.
class VideoSurfaceEvent extends Equatable {
  const VideoSurfaceEvent({this.ready, this.width, this.height});

  final bool? ready;
  final int? width;
  final int? height;

  @override
  List<Object?> get props => [ready, width, height];
}

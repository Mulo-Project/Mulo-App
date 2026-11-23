import 'package:equatable/equatable.dart';

import 'download_options.dart';

/// 설정의 기본 저장 형식 (상세 기능: 기본 음질·포맷 설정 #24). 소리(음원)와 영상을 따로 정한다.
/// 음원 음질은 고르지 않고 항상 원본 기준 최고다.
class DownloadPreferences extends Equatable {
  const DownloadPreferences({
    this.format = AudioFormat.opus,
    this.videoFormat = VideoFormat.mp4,
    this.videoHeight = 1080,
  });

  final AudioFormat format;
  final VideoFormat videoFormat;
  final int videoHeight;

  DownloadPreferences copyWith({
    AudioFormat? format,
    VideoFormat? videoFormat,
    int? videoHeight,
  }) => DownloadPreferences(
    format: format ?? this.format,
    videoFormat: videoFormat ?? this.videoFormat,
    videoHeight: videoHeight ?? this.videoHeight,
  );

  @override
  List<Object?> get props => [format, videoFormat, videoHeight];
}

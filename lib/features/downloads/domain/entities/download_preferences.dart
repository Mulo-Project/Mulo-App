import 'package:equatable/equatable.dart';

import 'download_options.dart';

/// 설정의 기본 음질 · 저장 형식 (상세 기능: 기본 음질·포맷 설정 #24).
class DownloadPreferences extends Equatable {
  const DownloadPreferences({
    this.quality = Quality.best,
    this.format = AudioFormat.opus,
  });

  final Quality quality;
  final AudioFormat format;

  DownloadPreferences copyWith({Quality? quality, AudioFormat? format}) =>
      DownloadPreferences(
        quality: quality ?? this.quality,
        format: format ?? this.format,
      );

  @override
  List<Object?> get props => [quality, format];
}

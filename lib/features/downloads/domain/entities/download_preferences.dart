import 'package:equatable/equatable.dart';

import 'download_options.dart';

/// 설정의 기본 저장 형식 (상세 기능: 기본 음질·포맷 설정 #24). 음질은 고르지 않고 항상 원본 기준 최고다.
class DownloadPreferences extends Equatable {
  const DownloadPreferences({this.format = AudioFormat.opus});

  final AudioFormat format;

  DownloadPreferences copyWith({AudioFormat? format}) =>
      DownloadPreferences(format: format ?? this.format);

  @override
  List<Object?> get props => [format];
}

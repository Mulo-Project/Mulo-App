import 'package:equatable/equatable.dart';

import 'audio_stream.dart';
import 'media_info.dart';

/// 곡 주소로 읽기부터 재생까지 네이티브에 맡기는 요청 (미리 듣기 시작).
/// 네이티브가 모르는 것(저장한 곡의 받아 둔 주소 · 설정 화질)만 앱이 채워 보낸다.
class PreviewPage extends Equatable {
  const PreviewPage({
    required this.hit,
    this.audioLanguage,
    this.maxHeight,
    this.saved,
  });

  /// 미리 듣는 곡 (네이티브가 곡 정보로도 쥔다).
  final MediaHit hit;

  /// 고른 오디오 언어 (null이면 기본 음성).
  final String? audioLanguage;

  /// 소리가 든 영상 형식을 고를 화질의 높이 상한 (null이면 소리 주소만 읽는다).
  final int? maxHeight;

  /// 저장해 둔 곡이면 그 소리 주소 (있으면 링크를 풀지 않고 이것을 튼다).
  final AudioStream? saved;

  @override
  List<Object?> get props => [hit, audioLanguage, maxHeight, saved];
}

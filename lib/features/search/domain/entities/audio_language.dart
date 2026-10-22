import 'package:equatable/equatable.dart';

/// 영상에 들어 있는 오디오 언어 트랙 하나 (더빙 · 다국어 음원).
class AudioLanguage extends Equatable {
  const AudioLanguage({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  /// 언어 코드 (`ko`, `en-US` 등). 미리 듣기 · 받기에 그대로 넘긴다.
  final String id;

  /// 유튜브가 알려 준 표시 이름 (예: `Korean`). 모르면 [id].
  final String name;

  /// 영상의 원래(기본) 음성.
  final bool isDefault;

  @override
  List<Object?> get props => [id, name, isDefault];
}

/// 유튜브 오디오 트랙 id(`en-US.4`)에서 언어 코드(`en-US`)만 뗀다.
String audioLanguageId(String trackId) {
  final dot = trackId.lastIndexOf('.');
  return dot > 0 ? trackId.substring(0, dot) : trackId;
}

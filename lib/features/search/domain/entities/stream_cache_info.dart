import 'package:equatable/equatable.dart';

/// 스트리밍(받지 않고 듣기) 임시 저장소의 사용량과 한도. 한도 0은 끈 상태.
class StreamCacheInfo extends Equatable {
  const StreamCacheInfo({
    required this.usedBytes,
    required this.limitBytes,
    this.savedBytes = 0,
    this.freeBytes = 0,
  });

  final int usedBytes;
  final int limitBytes;

  /// 저장한 음원(지워지지 않는 저장 저장소)이 쓰는 용량.
  final int savedBytes;

  /// 기기에 남은 저장 공간.
  final int freeBytes;

  bool get enabled => limitBytes > 0;

  @override
  List<Object?> get props => [usedBytes, limitBytes, savedBytes, freeBytes];
}

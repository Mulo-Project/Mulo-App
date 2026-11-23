import 'package:equatable/equatable.dart';

/// 한도를 두지 않는 값 (네이티브 Long 최댓값). 직접 비우기 전까지 계속 쌓인다.
const streamCacheUnlimited = 0x7fffffffffffffff;

/// 스트리밍(받지 않고 듣기) 임시 저장소의 사용량과 한도. 한도 0은 끈 상태, [streamCacheUnlimited]는 무제한.
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

  bool get unlimited => limitBytes >= streamCacheUnlimited;

  @override
  List<Object?> get props => [usedBytes, limitBytes, savedBytes, freeBytes];
}

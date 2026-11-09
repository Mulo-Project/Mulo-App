import 'package:equatable/equatable.dart';

/// 스트리밍(받지 않고 듣기) 임시 저장소의 사용량과 한도. 한도 0은 끈 상태.
class StreamCacheInfo extends Equatable {
  const StreamCacheInfo({required this.usedBytes, required this.limitBytes});

  final int usedBytes;
  final int limitBytes;

  bool get enabled => limitBytes > 0;

  @override
  List<Object?> get props => [usedBytes, limitBytes];
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/stream_cache_info.dart';
import '../../domain/usecases/search_usecases.dart';

/// 스트리밍 임시 저장소의 사용량 · 한도 (상태)와 비우기.
class StreamCacheCubit extends Cubit<StreamCacheInfo> {
  StreamCacheCubit(this._info, this._clear)
    : super(const StreamCacheInfo(usedBytes: 0, limitBytes: 0));

  final GetStreamCacheInfo _info;
  final ClearStreamCache _clear;

  Future<void> load() async {
    try {
      final info = await _info(const NoParams());
      if (!isClosed) emit(info);
    } on Object {
      // 네이티브 저장소를 못 읽어도 설정 화면은 그대로 둔다.
    }
  }

  Future<void> clear() async {
    await _clear(const NoParams());
    await load();
  }
}

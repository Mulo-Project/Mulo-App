import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/search_usecases.dart';

class PreviewVideoState extends Equatable {
  const PreviewVideoState({this.url, this.headers = const {}});

  /// 영상 스트림 주소. 아직 읽는 중이거나 읽지 못했으면 null (그동안은 커버가 보인다).
  final String? url;
  final Map<String, String> headers;

  @override
  List<Object?> get props => [url, headers];
}

/// 미리 듣는 곡의 영상 화면 주소를 읽는다. 소리는 미리 듣기 플레이어가 따로 내므로
/// 영상을 못 읽어도 소리에는 영향이 없다 (조용히 커버를 계속 보여 준다).
class PreviewVideoCubit extends Cubit<PreviewVideoState> {
  PreviewVideoCubit(this._resolve) : super(const PreviewVideoState());

  final ResolveVideoStream _resolve;
  var _generation = 0;

  Future<void> load(String pageUrl) async {
    final generation = ++_generation;
    emit(const PreviewVideoState());
    if (pageUrl.isEmpty) return;
    try {
      final stream = await _resolve(pageUrl);
      if (generation != _generation || isClosed) return;
      emit(PreviewVideoState(url: stream.url, headers: stream.headers));
    } catch (_) {
      // 영상은 덤이다: 못 읽으면 커버를 그대로 둔다.
    }
  }
}

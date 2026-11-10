import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/video_quality.dart';
import '../../domain/usecases/search_usecases.dart';

class PreviewVideoState extends Equatable {
  const PreviewVideoState({this.started = false});

  /// 네이티브가 영상을 틀기 시작했다 (화면은 영상 화면으로 나간다). 아직이거나 못 열었으면 false.
  final bool started;

  @override
  List<Object?> get props => [started];
}

/// 미리 듣는 곡의 영상 주소를 읽어 네이티브에 틀라고 한다. 소리는 미리 듣기 플레이어가 따로 내므로
/// 영상을 못 열어도 소리에는 영향이 없다 (조용히 커버를 계속 보여 준다).
class PreviewVideoCubit extends Cubit<PreviewVideoState> {
  PreviewVideoCubit(this._resolve, this._play)
    : super(const PreviewVideoState());

  final ResolveVideoStream _resolve;
  final PlayPreviewVideo _play;
  var _generation = 0;

  /// [quality]는 저장한 곡의 화질 (없으면 설정 화질).
  Future<void> load(String pageUrl, {VideoQuality? quality}) async {
    final generation = ++_generation;
    emit(const PreviewVideoState());
    if (pageUrl.isEmpty) return;
    try {
      final stream = await _resolve(pageUrl, quality: quality);
      if (generation != _generation || isClosed) return;
      await _play(stream);
      if (generation != _generation || isClosed) return;
      debugPrint('[video] 영상 시작: ${Uri.tryParse(stream.url)?.host}');
      emit(const PreviewVideoState(started: true));
    } catch (e) {
      // 영상은 덤이다: 못 열면 커버를 그대로 두고, 까닭만 로그로 남긴다.
      debugPrint('[video] 영상을 못 열음 ($pageUrl): $e');
    }
  }
}

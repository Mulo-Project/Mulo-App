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
  PreviewVideoCubit(this._resolve, this._play, this._playMain)
    : super(const PreviewVideoState());

  final ResolveVideoStream _resolve;
  final PlayPreviewVideo _play;
  final PlayMainVideo _playMain;
  var _generation = 0;
  var _followingMain = false;

  /// [quality]는 저장한 곡의 화질 (없으면 설정 화질). [online]이면 소리만 저장한 곡도 영상을 읽는다.
  Future<void> load(
    String pageUrl, {
    VideoQuality? quality,
    bool online = false,

    /// 미리 듣기가 아니라 메인 재생 소리(임시 저장한 음원)에 맞춰 영상을 튼다 (스트림).
    bool followMain = false,
  }) async {
    final generation = ++_generation;
    emit(const PreviewVideoState());
    if (pageUrl.isEmpty) return;
    try {
      final stream = await _resolve(pageUrl, quality: quality, online: online);
      if (generation != _generation || isClosed) return;
      if (followMain) {
        _followingMain = true;
        await _playMain(stream);
      } else {
        await _play(stream);
      }
      if (generation != _generation || isClosed) return;
      debugPrint('[video] 영상 시작: ${Uri.tryParse(stream.url)?.host}');
      emit(const PreviewVideoState(started: true));
    } catch (e) {
      // 영상은 덤이다: 못 열면 커버를 그대로 두고, 까닭만 로그로 남긴다.
      debugPrint('[video] 영상을 못 열음 ($pageUrl): $e');
    }
  }

  @override
  Future<void> close() {
    // 메인 소리를 따르던 영상은 화면이 사라지면 멈춘다 (미리 듣기 영상은 미리 듣기가 쥔다).
    if (_followingMain) {
      _followingMain = false;
      _playMain(null).catchError((Object _) {});
    }
    return super.close();
  }
}

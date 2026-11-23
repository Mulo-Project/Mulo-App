import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/video_surface_info.dart';
import '../../domain/usecases/video_surface_usecases.dart';

class VideoSurfaceState extends Equatable {
  const VideoSurfaceState({
    this.textureId,
    this.ready = false,
    this.width = 0,
    this.height = 0,
    this.pip = false,
  });

  /// 영상 화면(텍스처). 아직 받지 못했거나 지원하지 않으면 null.
  final int? textureId;

  /// 영상의 첫 화면이 그려졌다 (그때까지는 커버를 보여 준다).
  final bool ready;
  final int width;
  final int height;

  /// 작은 창(PiP)에 떠 있다: 앱은 영상만 꽉 채워 보여 준다.
  final bool pip;

  VideoSurfaceState copyWith({
    int? textureId,
    bool? ready,
    int? width,
    int? height,
    bool? pip,
  }) => VideoSurfaceState(
    textureId: textureId ?? this.textureId,
    ready: ready ?? this.ready,
    width: width ?? this.width,
    height: height ?? this.height,
    pip: pip ?? this.pip,
  );

  @override
  List<Object?> get props => [textureId, ready, width, height, pip];
}

/// 네이티브 영상 화면을 앱 전체가 하나로 나눠 쓴다. 영상 위젯이 보이는 동안만 네이티브에 붙어 있고
/// (영상 해독이 켜진다), 모두 사라진 뒤 잠시 지나면 뗀다 (화면을 옮기는 사이에는 이어서 쓴다).
class VideoSurfaceCubit extends Cubit<VideoSurfaceState> {
  VideoSurfaceCubit(this._attach, this._detach, WatchVideoSurface watch)
    : super(const VideoSurfaceState()) {
    _sub = watch(const NoParams()).listen(_onEvent);
  }

  final AttachVideoSurface _attach;
  final DetachVideoSurface _detach;
  late final StreamSubscription<VideoSurfaceEvent> _sub;

  static const _graceTime = Duration(seconds: 3);
  var _refs = 0;
  var _attached = false;
  Timer? _grace;

  void _onEvent(VideoSurfaceEvent e) {
    if (isClosed) return;
    emit(
      state.copyWith(
        ready: e.ready,
        width: e.width,
        height: e.height,
        pip: e.pip,
      ),
    );
  }

  /// 영상 위젯이 보이기 시작했다.
  Future<void> acquire() async {
    _refs++;
    _grace?.cancel();
    if (_attached) return;
    _attached = true;
    final VideoSurfaceInfo? info;
    try {
      info = await _attach(const NoParams());
    } catch (_) {
      _attached = false;
      return;
    }
    if (isClosed) return;
    if (info == null) {
      _attached = false;
      return;
    }
    emit(
      VideoSurfaceState(
        textureId: info.textureId,
        ready: info.ready,
        width: info.width,
        height: info.height,
        pip: state.pip,
      ),
    );
  }

  /// 영상 위젯이 사라졌다.
  void release() {
    _refs--;
    if (_refs > 0) return;
    _grace?.cancel();
    _grace = Timer(_graceTime, () async {
      if (_refs > 0 || !_attached || isClosed) return;
      _attached = false;
      emit(state.copyWith(ready: false));
      await _detach(const NoParams());
    });
  }

  @override
  Future<void> close() async {
    _grace?.cancel();
    await _sub.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/preview_progress.dart';
import '../../domain/usecases/search_usecases.dart';

enum PreviewStatus { idle, loading, playing }

class PreviewState extends Equatable {
  const PreviewState({
    this.hitId,
    this.status = PreviewStatus.idle,
    this.progress,
    this.error,
  });

  /// 미리 듣는 중(또는 준비 중)인 검색 결과의 id. 아무것도 안 듣고 있으면 null.
  final String? hitId;
  final PreviewStatus status;

  /// 재생 중에 실패해 멈췄을 때의 까닭 (그 밖에는 null).
  final String? error;

  /// 재생 중일 때 어디까지 들었는지 (아직 소리가 안 나면 null).
  final PreviewProgress? progress;

  /// 들은 비율 0 ~ 1 (길이를 모르면 0).
  double get fraction {
    final p = progress;
    final d = p?.duration;
    if (p == null || d == null || d == Duration.zero) return 0;
    return (p.position.inMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);
  }

  bool isActive(String id) => hitId == id && status != PreviewStatus.idle;

  @override
  List<Object?> get props => [hitId, status, progress, error];
}

/// 검색 결과 미리 듣기: 다운로드 없이 오디오 스트림 주소를 받아 바로 재생한다.
/// 메인 재생(대기열)과 섞이지 않는 별도 플레이어를 쓰고, 한 번에 한 곡만 들린다.
/// 다른 곡을 미리 들으면 앞의 곡은 멈춘다. 앱 전체에서 하나만 쓴다 (MultiBlocProvider).
class PreviewCubit extends Cubit<PreviewState> {
  PreviewCubit(
    this._resolve,
    this._play,
    this._stop,
    WatchPreviewCompleted watchCompleted,
    WatchPreviewProgress watchProgress,
    WatchPreviewFailures watchFailures,
  ) : super(const PreviewState()) {
    _completed = watchCompleted(const NoParams()).listen((_) => stop());
    _progress = watchProgress(const NoParams()).listen(_onProgress);
    _failures = watchFailures(const NoParams()).listen(_onFailure);
  }

  final ResolveAudioStream _resolve;
  final PlayPreview _play;
  final StopPreview _stop;
  late final StreamSubscription<void> _completed;
  late final StreamSubscription<PreviewProgress> _progress;
  late final StreamSubscription<String> _failures;

  /// 재생 중에 실패하면 멈춘 상태로 돌리고 까닭을 [PreviewState.error]로 알린다.
  void _onFailure(String reason) {
    if (isClosed || state.status == PreviewStatus.idle) return;
    emit(PreviewState(error: reason));
  }

  void _onProgress(PreviewProgress p) {
    if (isClosed || state.status != PreviewStatus.playing) return;
    emit(PreviewState(hitId: state.hitId, status: state.status, progress: p));
  }

  /// 이만큼 걸려도 안 되면 "준비 중"에 멈춰 있지 않고 실패로 돌린다.
  static const _resolveTimeout = Duration(seconds: 60);
  static const _playTimeout = Duration(seconds: 30);

  /// 마지막으로 시작하지 못했을 때의 자세한 까닭 (안내에 덧붙여 보여 준다).
  String lastFailureDetail = '';

  /// 시작 · 멈춤마다 올린다. 느리게 돌아온 이전 요청의 결과를 버리려고.
  var _generation = 0;

  /// [hit]을 미리 듣는다. 이미 듣는 중이면 멈춘다.
  /// 시작하지 못했으면 까닭을, 잘 됐거나 중간에 취소됐으면 null을 돌려준다.
  Future<EngineFailure?> toggle(MediaHit hit) async {
    if (state.isActive(hit.id)) {
      await stop();
      return null;
    }
    final generation = ++_generation;
    // 앞에 듣던 곡은 새 곡 주소를 알아내는 동안에도 바로 멈춘다.
    if (state.status != PreviewStatus.idle) unawaited(_stop(const NoParams()));
    emit(PreviewState(hitId: hit.id, status: PreviewStatus.loading));
    try {
      final stream = await _resolve(hit.url).timeout(_resolveTimeout);
      if (generation != _generation || isClosed) return null;
      await _play(stream).timeout(_playTimeout);
      if (generation != _generation || isClosed) {
        // 불러오는 사이에 멈춤이 눌렸다면 늦게 시작된 소리를 끈다.
        // (다른 곡이 눌린 거라면 그 곡의 소리라서 그대로 둔다.)
        if (state.status == PreviewStatus.idle) await _stop(const NoParams());
        return null;
      }
      emit(PreviewState(hitId: hit.id, status: PreviewStatus.playing));
      return null;
    } on EngineException catch (e) {
      if (generation != _generation || isClosed) return null;
      emit(const PreviewState());
      lastFailureDetail = e.message;
      return e.failure;
    } catch (e) {
      // 예상 못 한 오류에도 "준비 중"에 멈춰 있지 않게 실패로 돌린다.
      if (generation != _generation || isClosed) return null;
      emit(const PreviewState());
      lastFailureDetail = '$e';
      return EngineFailure.failed;
    }
  }

  /// 미리 듣기를 멈춘다 (듣고 있지 않으면 아무 일도 없다).
  Future<void> stop() async {
    _generation++;
    if (state.status == PreviewStatus.idle) return;
    if (!isClosed) emit(const PreviewState());
    await _stop(const NoParams());
  }

  @override
  Future<void> close() async {
    await _completed.cancel();
    await _progress.cancel();
    await _failures.cancel();
    await _stop(const NoParams());
    return super.close();
  }
}

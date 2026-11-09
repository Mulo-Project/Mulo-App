import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/saved_video.dart';
import '../../domain/entities/video_quality.dart';
import '../../domain/usecases/saved_video_usecases.dart';

/// 보관한 영상 목록과 담기 · 빼기. 앱 전체에서 하나만 쓴다 (상세 화면의 보관 버튼과 보관 페이지가 함께 본다).
class SavedVideosCubit extends Cubit<List<SavedVideo>> {
  SavedVideosCubit(
    this._load,
    this._save,
    this._remove,
    this._markReady,
    WatchSavedDone watchDone, {
    ResumeSavedVideos? resume,
  }) : _resume = resume,
       super(const []) {
    _done = watchDone(const NoParams()).listen(_onDone);
    unawaited(load().then((_) => _resumeUnfinished()));
  }

  final LoadSavedVideos _load;
  final SaveVideo _save;
  final RemoveSavedVideo _remove;
  final MarkSavedVideoReady _markReady;
  final ResumeSavedVideos? _resume;
  late final StreamSubscription<({String id, bool ok})> _done;

  /// 보관을 시작했지만 주소를 읽는 중인 영상 id (버튼을 잠시 막는다).
  final _busy = <String>{};

  bool contains(String id) => state.any((v) => v.id == id);

  /// 저장한 곡의 영상 화질 (저장하지 않았거나 음원이면 null).
  VideoQuality? qualityOf(String id) =>
      state.where((v) => v.id == id).firstOrNull?.quality;
  bool isBusy(String id) => _busy.contains(id);

  Future<void> load() async {
    try {
      final list = await _load(const NoParams());
      if (!isClosed) emit(list);
    } on Object {
      // 읽지 못하면 빈 목록으로 둔다.
    }
  }

  Timer? _retry;
  var _retryDelay = const Duration(seconds: 30);

  /// 받다가 끊긴 곡을 지금 이어 받는다 (저장한 음원 화면을 열 때도 부른다).
  Future<void> retry() => _resumeUnfinished();

  /// 받다가 끊긴 곡을 이어 받는다. 실패해도 목록은 그대로다.
  Future<void> _resumeUnfinished() async {
    final resume = _resume;
    if (resume == null || !state.any((v) => !v.ready)) return;
    try {
      final list = await resume(const NoParams());
      if (!isClosed) emit(list);
    } on Object {
      // 못 이어 받으면 다음에 켤 때 다시 시도한다.
    }
  }

  /// 저장한다 ([quality]는 유튜브 영상의 화질). 주소를 못 읽으면 false.
  Future<bool> add(MediaHit hit, {VideoQuality? quality}) async {
    if (!_busy.add(hit.id)) return true;
    try {
      final list = await _save(SaveVideoParams(hit, quality: quality));
      if (!isClosed) emit(list);
      return true;
    } on Object {
      return false;
    } finally {
      _busy.remove(hit.id);
    }
  }

  Future<void> remove(String id) async {
    final list = await _remove(id);
    if (!isClosed) emit(list);
  }

  /// 저장한 곡을 모두 뺀다.
  Future<void> removeAll() async {
    for (final v in List.of(state)) {
      await remove(v.id);
    }
  }

  Future<void> _onDone(({String id, bool ok}) e) async {
    if (isClosed) return;
    if (!e.ok) {
      // 끊겼다: 잠시 뒤 다시 이어 받는다 (30초부터 늘려 가며 최대 5분 간격). 네트워크가 돌아오면 그때 이어진다.
      _retry?.cancel();
      _retry = Timer(_retryDelay, retry);
      _retryDelay = Duration(
        seconds: (_retryDelay.inSeconds * 2).clamp(30, 300),
      );
      return;
    }
    _retryDelay = const Duration(seconds: 30);
    final list = await _markReady(e.id);
    if (!isClosed) emit(list);
  }

  @override
  Future<void> close() async {
    _retry?.cancel();
    await _done.cancel();
    return super.close();
  }
}

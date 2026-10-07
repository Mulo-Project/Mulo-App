import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/usecases/download_usecases.dart';

class DownloadQueueState extends Equatable {
  const DownloadQueueState({this.items = const []});

  final List<DownloadItem> items;

  /// 카드에 보여 줄 곡: 지금 받는 곡, 없으면 일시정지한 첫 곡, 없으면 실패한 첫 곡 (다시 받기 버튼을 보이려고).
  DownloadItem? get current {
    for (final i in items) {
      if (i.status == DownloadStatus.downloading) return i;
    }
    for (final i in items) {
      if (i.status == DownloadStatus.paused) return i;
    }
    for (final i in items) {
      if (i.status == DownloadStatus.failed) return i;
    }
    return null;
  }

  /// 받기가 끝난 곡 수 (끝난 곡이 생기면 커버 · 색을 다시 읽으려고 센다).
  int get doneCount =>
      items.where((i) => i.status == DownloadStatus.done).length;

  /// 아직 끝나지 않은(받는 중 · 대기 · 일시정지 · 실패) 곡 수.
  int get unfinishedCount =>
      items.where((i) => i.status != DownloadStatus.done).length;

  /// [playlistId] 재생목록에 담기로 한, 아직 끝나지 않은 곡들 (재생목록 화면의 받기 영역).
  List<DownloadItem> unfinishedFor(String playlistId) => [
    for (final i in items)
      if (i.status != DownloadStatus.done && i.playlistIds.contains(playlistId))
        i,
  ];

  /// 큐에 있는 곡 전체의 받기 진행도 (0 ~ 1). 끝난 곡은 1로 센다.
  double get overallProgress {
    if (items.isEmpty) return 0;
    final sum = items.fold<double>(
      0,
      (a, i) => a + (i.status == DownloadStatus.done ? 1 : i.progress),
    );
    return (sum / items.length).clamp(0, 1);
  }

  @override
  List<Object?> get props => [items];
}

/// 검색 탭의 다운로드 카드 · 대기열. 대기열 변경을 구독한다.
class DownloadQueueCubit extends Cubit<DownloadQueueState> {
  DownloadQueueCubit(
    this._watch,
    this._enqueue,
    this._pause,
    this._resume,
    this._retry,
    this._cancel,
    this._cancelAll,
  ) : super(const DownloadQueueState());

  final WatchDownloadQueue _watch;
  final EnqueueDownload _enqueue;
  final PauseDownload _pause;
  final ResumeDownload _resume;
  final RetryDownload _retry;
  final CancelDownload _cancel;
  final CancelAllDownloads _cancelAll;
  StreamSubscription<List<DownloadItem>>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _watch(const NoParams())
        .listen((items) => emit(DownloadQueueState(items: items)));
  }

  /// 팝업에서 정한 정보로 받기를 시작한다. 제목이 비어 있으면 false.
  Future<bool> enqueue(DownloadRequest request) => _enqueue(request);

  Future<void> pause(String id) => _pause(id);

  Future<void> resume(String id) => _resume(id);

  Future<void> retry(String id) => _retry(id);

  Future<void> cancel(String id) => _cancel(id);

  /// 끝나지 않은 받기를 모두 취소한다 ([playlistId]가 있으면 그 재생목록 것만). 취소한 곡 수를 돌려준다.
  Future<int> cancelAll({String? playlistId}) => _cancelAll(playlistId);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

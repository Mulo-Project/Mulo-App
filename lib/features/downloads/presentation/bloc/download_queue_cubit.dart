import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/usecases/download_usecases.dart';

class DownloadQueueState extends Equatable {
  const DownloadQueueState({
    this.items = const [],
    this.downloadedKeys = const {},
  });

  final List<DownloadItem> items;

  /// 이미 받아 보관함에 있는 곡들의 원본 주소 키.
  final Set<String> downloadedKeys;

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

  /// [playlistId] 재생목록 카드에 보여 줄 곡: 지금 받는 곡, 없으면 대기 · 일시정지한 첫 곡. 실패만 남았으면 null.
  DownloadItem? activeFor(String playlistId) {
    final mine = unfinishedFor(playlistId);
    for (final s in const [
      DownloadStatus.downloading,
      DownloadStatus.queued,
      DownloadStatus.paused,
    ]) {
      for (final i in mine) {
        if (i.status == s) return i;
      }
    }
    return null;
  }

  /// 끝나지 않은 곡이 모두 일시정지 상태인가 (전체 일시정지 버튼이 "이어 받기"로 바뀐다).
  bool get allPaused {
    final live = items.where(
      (i) =>
          i.status != DownloadStatus.done && i.status != DownloadStatus.failed,
    );
    return live.isNotEmpty &&
        live.every((i) => i.status == DownloadStatus.paused);
  }

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
  List<Object?> get props => [items, downloadedKeys];
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
    this._cancelAll, [
    this._watchDownloaded,
  ]) : super(const DownloadQueueState());

  final WatchDownloadQueue _watch;
  final EnqueueDownload _enqueue;
  final PauseDownload _pause;
  final ResumeDownload _resume;
  final RetryDownload _retry;
  final CancelDownload _cancel;
  final CancelAllDownloads _cancelAll;
  final WatchDownloadedKeys? _watchDownloaded;
  StreamSubscription<List<DownloadItem>>? _sub;

  StreamSubscription<Set<String>>? _keysSub;

  void start() {
    _sub?.cancel();
    _keysSub?.cancel();
    _sub = _watch(const NoParams()).listen((items) {
      emit(
        DownloadQueueState(items: items, downloadedKeys: state.downloadedKeys),
      );
    });
    // 곡을 받거나 지울 때마다 받은 곡 목록이 새로 온다 (지운 곡은 다시 받을 수 있다).
    _keysSub = _watchDownloaded?.call(const NoParams()).listen((keys) {
      if (!isClosed) {
        emit(DownloadQueueState(items: state.items, downloadedKeys: keys));
      }
    });
  }

  /// 이미 받아 보관함에 있는 곡인지.
  bool isDownloaded(String url) =>
      state.downloadedKeys.contains(downloadSourceKey(url));

  /// 같은 원본 주소의 곡이 이미 받는 중 · 대기 · 일시정지인지.
  bool isInQueue(String url) {
    final key = downloadSourceKey(url);
    return state.items.any(
      (e) => e.isActive && downloadSourceKey(e.url) == key,
    );
  }

  /// 팝업에서 정한 정보로 받기를 시작한다. 제목이 비어 있으면 false.
  Future<bool> enqueue(DownloadRequest request) => _enqueue(request);

  Future<void> pause(String id) => _pause(id);

  Future<void> resume(String id) => _resume(id);

  /// 받는 중 · 대기 중인 곡을 모두 일시정지한다.
  /// 받는 곡을 먼저 멈추면 다음 대기 곡이 바로 받기 시작하므로, 대기 곡을 먼저 멈추고 받는 곡을 마지막에 멈춘다.
  Future<void> pauseAll() async {
    {
      final live =
          [
            for (final i in state.items)
              if (i.status == DownloadStatus.downloading ||
                  i.status == DownloadStatus.queued)
                i,
          ]..sort(
            (a, b) =>
                (a.status == DownloadStatus.queued ? 0 : 1) -
                (b.status == DownloadStatus.queued ? 0 : 1),
          );
      for (final i in live) {
        await _pause(i.id);
      }
    }
  }

  /// 일시정지한 곡을 모두 이어 받는다.
  Future<void> resumeAll() async {
    for (final i in state.items) {
      if (i.status == DownloadStatus.paused) await _resume(i.id);
    }
  }

  Future<void> retry(String id) => _retry(id);

  Future<void> cancel(String id) => _cancel(id);

  /// 끝나지 않은 받기를 모두 취소한다 ([playlistId]가 있으면 그 재생목록 것만). 취소한 곡 수를 돌려준다.
  Future<int> cancelAll({String? playlistId}) => _cancelAll(playlistId);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _keysSub?.cancel();
    return super.close();
  }
}

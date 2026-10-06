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

  /// 현재 곡을 뺀, 아직 끝나지 않은 곡들.
  List<DownloadItem> get waiting {
    final now = current;
    return [
      for (final i in items)
        if ((i.isActive || i.status == DownloadStatus.failed) && i != now) i,
    ];
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
  ) : super(const DownloadQueueState());

  final WatchDownloadQueue _watch;
  final EnqueueDownload _enqueue;
  final PauseDownload _pause;
  final ResumeDownload _resume;
  final RetryDownload _retry;
  final CancelDownload _cancel;
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

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

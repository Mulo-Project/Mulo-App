import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/usecases/library_usecases.dart';

class LibraryImportState extends Equatable {
  const LibraryImportState({
    this.running = false,
    this.outcome,
    this.seq = 0,
    this.coversSeq = 0,
  });

  final bool running;

  /// 마지막 결과. 화면이 [seq]가 바뀔 때 한 번 안내한다.
  final ImportOutcome? outcome;
  final int seq;

  /// 내장 커버를 새로 붙일 때마다 오른다 (화면이 커버 목록을 다시 읽는다).
  final int coversSeq;

  @override
  List<Object?> get props => [running, outcome, seq, coversSeq];
}

/// 기기 음악 불러오기 (#11). 곡 목록을 먼저 보여 준 뒤 뒤에서 파일 내장 커버를 채운다.
class LibraryImportCubit extends Cubit<LibraryImportState> {
  LibraryImportCubit(
    this._import,
    this._fillCovers, [
    this._embedTags,
    this._restoreTags,
  ]) : super(const LibraryImportState());

  final ImportDeviceMusic _import;
  final FillEmbeddedCovers _fillCovers;
  final EmbedTagsIntoFiles? _embedTags;
  final RestoreFromFileTags? _restoreTags;
  Timer? _embedTimer;
  bool _filling = false;

  Future<void> importDeviceMusic() async {
    if (state.running) return;
    emit(
      LibraryImportState(
        running: true,
        outcome: state.outcome,
        seq: state.seq,
        coversSeq: state.coversSeq,
      ),
    );
    final outcome = await _import(const NoParams());
    if (isClosed) return;
    emit(
      LibraryImportState(
        outcome: outcome,
        seq: state.seq + 1,
        coversSeq: state.coversSeq,
      ),
    );
    // 새 곡이 없어도 이미 가져온 곡의 빈 커버를 채운다 (지난번에 못 채운 곡도 다시 시도한다).
    if (outcome is ImportAdded) await _restoreFromTags();
    await _fillEmbeddedCovers();
  }

  /// 파일 태그를 읽어 곡 정보 · 커버 편집 상태를 DB에 되살린다 (파일이 원본). 곡 목록은 DB 스트림이 갱신한다.
  Future<void> _restoreFromTags() async {
    final restore = _restoreTags;
    if (restore == null) return;
    try {
      final restored = await restore(const NoParams());
      if (isClosed || restored == 0) return;
      emit(
        LibraryImportState(
          outcome: state.outcome,
          seq: state.seq,
          coversSeq: state.coversSeq + 1,
        ),
      );
    } on Exception {
      // 못 읽어도 가져오기 결과에는 영향이 없다 (곡마다 기록해 다음에 이어서).
    }
  }

  Future<void> _fillEmbeddedCovers() async {
    if (_filling) return;
    _filling = true;
    try {
      final filled = await _fillCovers(const NoParams());
      if (isClosed || filled == 0) return;
      emit(
        LibraryImportState(
          outcome: state.outcome,
          seq: state.seq,
          coversSeq: state.coversSeq + 1,
        ),
      );
    } on Exception {
      // 커버를 못 채워도 가져오기 결과에는 영향이 없다.
    } finally {
      _filling = false;
    }
  }

  /// 받아 둔 곡의 파일 태그를 뒤에서 채운다 (앱 시작을 막지 않도록 잠시 뒤에, 곡마다 기록해 이어서).
  void embedTagsInBackground({Duration delay = const Duration(seconds: 5)}) {
    final embed = _embedTags;
    if (embed == null || _embedTimer != null) return;
    _embedTimer = Timer(delay, () async {
      try {
        await embed(const NoParams());
      } on Exception {
        // 이관은 덤이라 실패해도 다음 실행에 이어서 한다.
      }
    });
  }

  @override
  Future<void> close() {
    _embedTimer?.cancel();
    return super.close();
  }
}

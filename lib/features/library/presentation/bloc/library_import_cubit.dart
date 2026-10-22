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
  LibraryImportCubit(this._import, this._fillCovers)
    : super(const LibraryImportState());

  final ImportDeviceMusic _import;
  final FillEmbeddedCovers _fillCovers;
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
    // 새 곡이 없어도 이미 가져온 곡의 빈 커버를 채운다.
    if (outcome is ImportAdded) await _fillEmbeddedCovers();
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
}

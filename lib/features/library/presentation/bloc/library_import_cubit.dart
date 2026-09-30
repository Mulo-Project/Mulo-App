import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/usecases/library_usecases.dart';

class LibraryImportState extends Equatable {
  const LibraryImportState({this.running = false, this.outcome, this.seq = 0});

  final bool running;

  /// 마지막 결과. 화면이 [seq]가 바뀔 때 한 번 안내한다.
  final ImportOutcome? outcome;
  final int seq;

  @override
  List<Object?> get props => [running, outcome, seq];
}

/// 기기 음악 불러오기 (#11).
class LibraryImportCubit extends Cubit<LibraryImportState> {
  LibraryImportCubit(this._import) : super(const LibraryImportState());

  final ImportDeviceMusic _import;

  Future<void> importDeviceMusic() async {
    if (state.running) return;
    emit(
      LibraryImportState(running: true, outcome: state.outcome, seq: state.seq),
    );
    final outcome = await _import(const NoParams());
    if (isClosed) return;
    emit(LibraryImportState(outcome: outcome, seq: state.seq + 1));
  }
}

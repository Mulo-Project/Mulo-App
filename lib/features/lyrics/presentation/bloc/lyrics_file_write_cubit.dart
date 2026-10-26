import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/lyrics_usecases.dart';

export '../../domain/usecases/lyrics_usecases.dart' show LyricsFileWriteResult;

/// 앱에 저장한 가사를 음원 파일의 가사 태그로 한꺼번에 옮긴다 (설정). 상태는 "옮기는 중인지".
class LyricsFileWriteCubit extends Cubit<bool> {
  LyricsFileWriteCubit({required this._count, required this._write})
    : super(false);

  final CountSavedLyricsTracks _count;
  final WriteSavedLyricsToFiles _write;

  /// 앱에 저장한 가사가 있는 곡 수.
  Future<int> count() => _count(const NoParams());

  /// 옮긴다. 한 곡이 끝날 때마다 [onProgress]로 (끝낸 수, 전체 수)를 알린다.
  /// 이미 옮기는 중이면 아무것도 하지 않고 null.
  Future<LyricsFileWriteResult?> run({
    void Function(int done, int total)? onProgress,
  }) async {
    if (state) return null;
    emit(true);
    try {
      return await _write(
        WriteSavedLyricsToFilesParams(onProgress: onProgress),
      );
    } finally {
      if (!isClosed) emit(false);
    }
  }
}

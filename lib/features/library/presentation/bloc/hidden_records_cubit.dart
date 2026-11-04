import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/hidden_track.dart';
import '../../domain/usecases/loaded_folder_usecases.dart';

/// 폴더를 빼서 숨겨 둔 곡 (상태)과 그 기록 정리.
class HiddenRecordsCubit extends Cubit<List<HiddenTrack>> {
  HiddenRecordsCubit(this._list, this._purge) : super(const []);

  final ListHiddenTracks _list;
  final PurgeHiddenTracks _purge;

  Future<void> load() async {
    final tracks = await _list(const NoParams());
    if (!isClosed) emit(tracks);
  }

  /// 숨긴 곡 하나의 기록을 지운다.
  Future<int> purgeOne(String id) => purge({id});

  /// 숨긴 곡의 기록을 지우고 지운 곡 수를 돌려준다. [ids]가 null이면 모두.
  Future<int> purge([Set<String>? ids]) async {
    final n = await _purge(ids);
    await load();
    return n;
  }
}

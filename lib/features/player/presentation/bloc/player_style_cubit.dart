import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/player_style.dart';
import '../../domain/usecases/player_style_usecases.dart';

export '../../domain/entities/player_style.dart';

/// 지금 쓰는 플레이어 모양. 고르면 저장한다.
class PlayerStyleCubit extends Cubit<PlayerStyle> {
  PlayerStyleCubit({
    required LoadPlayerStyle loadStyle,
    required SavePlayerStyle saveStyle,
  }) : _load = loadStyle,
       _save = saveStyle,
       super(PlayerStyle.initial);

  final LoadPlayerStyle _load;
  final SavePlayerStyle _save;
  bool _touched = false;

  /// 저장된 모양을 불러온다. 앱 시작 때 한 번.
  Future<void> load() async {
    final saved = await _load(const NoParams());
    // 불러오는 사이에 사용자가 이미 골랐으면 덮어쓰지 않는다.
    if (_touched || isClosed) return;
    emit(saved);
  }

  Future<void> select(PlayerStyle style) async {
    _touched = true;
    emit(style);
    await _save(style);
  }
}

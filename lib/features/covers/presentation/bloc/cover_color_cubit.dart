import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/cover_usecases.dart';

/// 곡 · 앨범 · 재생목록 커버 색 (키 → ARGB). 고르지 않은 키는 없다 (자동 색).
class CoverColorCubit extends Cubit<Map<String, int>> {
  CoverColorCubit({
    required this._load,
    required this._set,
    required this._clear,
  }) : super(const {});

  final LoadCoverColors _load;
  final SetCoverColor _set;
  final ClearCoverColor _clear;

  Future<void> load() async {
    final saved = await _load(const NoParams());
    // 불러오는 사이에 바뀐 값이 있으면 그쪽을 우선한다.
    if (!isClosed) emit({...saved, ...state});
  }

  Future<void> setColor(String key, Color color) async {
    final value = color.toARGB32();
    emit({...state, key: value});
    await _set(SetCoverColorParams(key, value));
  }

  /// 자동 색으로 되돌린다.
  Future<void> clear(String key) async {
    emit({...state}..remove(key));
    await _clear(key);
  }
}

/// [key]에 고른 색. 안 골랐으면 null (자동 색).
Color? coverColorOf(BuildContext context, String key) {
  final v = context.select<CoverColorCubit, int?>((c) => c.state[key]);
  return v == null ? null : Color(v);
}

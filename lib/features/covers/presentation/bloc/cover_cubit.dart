import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/cover_usecases.dart';

export '../../domain/entities/cover_key.dart';

/// 곡 · 재생목록 커버 이미지 (키 → 파일 경로). 앱 폴더 + DB에 저장되어 다시 켜도 유지된다.
class CoverCubit extends Cubit<Map<String, String>> {
  CoverCubit({
    required this._load,
    required PickCoverFromDevice pickFromDevice,
    required this._clear,
    required this._pickFile,
    required this._save,
  }) : _pick = pickFromDevice,
       super(const {});

  final LoadCovers _load;
  final PickCoverFromDevice _pick;
  final ClearCover _clear;
  final PickImageFile _pickFile;
  final SaveCover _save;

  Future<void> load() async {
    final saved = await _load(const NoParams());
    // 불러오는 사이에 바뀐 값이 있으면 그쪽을 우선한다.
    if (!isClosed) emit({...saved, ...state});
  }

  /// 기기에서 사진을 골라 [key]의 커버로 지정한다. 골랐으면 true.
  Future<bool> pickFromDevice(String key) async {
    final stored = await _pick(key);
    if (stored == null || isClosed) return false;
    emit({...state, key: stored});
    return true;
  }

  /// 기기에서 사진 한 장만 고른다 (아직 저장하지 않는다). 고른 파일 경로, 취소하면 null.
  Future<String?> pickFile() => _pickFile(const NoParams());

  /// [pickFile]로 고른 파일을 [key]의 커버로 저장한다.
  Future<void> setFromFile(String key, String sourcePath) async {
    final stored = await _save(SaveCoverParams(key, sourcePath));
    if (!isClosed) emit({...state, key: stored});
  }

  Future<void> clear(String key) async {
    emit({...state}..remove(key));
    await _clear(key);
  }
}

/// [key]의 커버 이미지. 없으면 null (기본 그라데이션 커버).
ImageProvider? coverImageOf(BuildContext context, String key) {
  final path = context.select<CoverCubit, String?>((c) => c.state[key]);
  return path == null ? null : FileImage(File(path));
}

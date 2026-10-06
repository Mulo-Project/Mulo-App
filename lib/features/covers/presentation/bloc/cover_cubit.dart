import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/cached_web_image.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/cover_art.dart';
import '../../domain/usecases/cover_usecases.dart';
import '../cover_image_provider.dart';

export '../../domain/entities/cover_art.dart';
export '../../domain/entities/cover_key.dart';

/// 곡 · 재생목록 커버 이미지 (키 → 커버). 기기 사진은 앱 폴더 + DB, 웹 이미지는 주소 + DB에
/// 저장되어 다시 켜도 유지된다.
class CoverCubit extends Cubit<Map<String, CoverArt>> {
  CoverCubit({
    required this._load,
    required this._clear,
    required this._pickFile,
    required this._save,
    required this._saveWeb,
    required this._setTransform,
  }) : super(const {});

  final LoadCovers _load;
  final ClearCover _clear;
  final PickImageFile _pickFile;
  final SaveCover _save;
  final SaveWebCover _saveWeb;
  final SetCoverTransform _setTransform;

  Future<void> load() async {
    final saved = await _load(const NoParams());
    // 불러오는 사이에 바뀐 값이 있으면 그쪽을 우선한다.
    if (!isClosed) emit({...saved, ...state});
  }

  /// 기기에서 사진 한 장만 고른다 (아직 저장하지 않는다). 고른 파일 경로, 취소하면 null.
  Future<String?> pickFile() => _pickFile(const NoParams());

  /// [pickFile]로 고른 파일을 [key]의 커버로 저장한다.
  Future<void> setFromFile(
    String key,
    String sourcePath, [
    CoverTransform transform = CoverTransform.identity,
  ]) async {
    final stored = await _save(SaveCoverParams(key, sourcePath, transform));
    if (!isClosed) emit({...state, key: stored});
  }

  /// 웹 이미지 [url]을 [key]의 커버로 쓴다 (주소와 위치만 저장).
  Future<void> setFromUrl(
    String key,
    String url, [
    CoverTransform transform = CoverTransform.identity,
  ]) async {
    final stored = await _saveWeb(SaveWebCoverParams(key, url, transform));
    if (!isClosed) emit({...state, key: stored});
  }

  /// 고른 [art]를 [key]에 저장한다 (기기 사진은 복사, 웹 이미지는 주소만).
  Future<void> setArt(String key, CoverArt art) => art.isWeb
      ? setFromUrl(key, art.url!, art.transform)
      : setFromFile(key, art.path!, art.transform);

  /// 이미 붙인 커버의 확대 · 위치만 바꾼다.
  Future<void> setTransform(String key, CoverTransform transform) async {
    final art = state[key];
    if (art == null) return;
    emit({...state, key: art.withTransform(transform)});
    await _setTransform(SetCoverTransformParams(key, transform));
  }

  Future<void> clear(String key) async {
    emit({...state}..remove(key));
    await _clear(key);
  }
}

/// [art]를 그리는 이미지 (위치 · 확대를 반영해 잘라 낸다).
ImageProvider imageOfCoverArt(CoverArt art) {
  final base = sourceImageOfCoverArt(art);
  // 손대지 않은 그림은 그대로 보여 줘서 칸 모양대로 채운다.
  return art.transform.isIdentity
      ? base
      : CoverImageProvider(base, art.transform);
}

/// 확대 · 위치를 적용하기 전의 원본 이미지.
ImageProvider sourceImageOfCoverArt(CoverArt art) =>
    art.isWeb ? CachedWebImage(art.url!) : FileImage(File(art.path!));

/// [key]의 커버 이미지. 없으면 null (기본 그라데이션 커버).
ImageProvider? coverImageOf(BuildContext context, String key) {
  final art = context.select<CoverCubit, CoverArt?>((c) => c.state[key]);
  return art == null ? null : imageOfCoverArt(art);
}

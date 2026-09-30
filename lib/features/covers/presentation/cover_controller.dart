import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/drift_cover_store.dart';

/// 커버 이미지를 붙일 대상의 키. 곡 · 재생목록이 같은 저장소를 쓴다.
abstract final class CoverKey {
  static String track(String id) => 'track:$id';
  static String playlist(String id) => 'playlist:$id';
}

/// 기기에서 이미지 한 장을 고른다. 테스트에서는 가짜로 바꾼다.
abstract interface class CoverImagePicker {
  /// 고른 파일 경로. 취소하면 null.
  Future<String?> pickImage();
}

class FilePickerCoverImagePicker implements CoverImagePicker {
  @override
  Future<String?> pickImage() async {
    // 한 장만 고른다 (pickFiles는 여러 장 선택 화면이 뜬다).
    final file = await FilePicker.pickFile(type: FileType.image);
    return file?.path;
  }
}

/// 커버 이미지 저장소: 고른 파일을 앱 폴더로 복사하고 키 → 경로를 기억한다.
abstract interface class CoverStore {
  Future<Map<String, String>> loadAll();

  /// [sourcePath]를 저장소로 복사하고 저장된 경로를 돌려준다.
  Future<String> save(String key, String sourcePath);
  Future<void> remove(String key);
}

final coverImagePickerProvider = Provider<CoverImagePicker>(
  (ref) => FilePickerCoverImagePicker(),
);

final coverStoreProvider = Provider<CoverStore>(
  (ref) => DriftCoverStore(ref.watch(appDatabaseProvider)),
);

/// 곡 · 재생목록 커버 이미지 (상세 기능: 커버 이미지 등록).
/// 앱 폴더 + DB(drift)에 저장해서 다시 켜도 유지된다.
class CoverController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    Future.microtask(_load);
    return const {};
  }

  Future<void> _load() async {
    final saved = await ref.read(coverStoreProvider).loadAll();
    // 불러오는 사이에 바뀐 값이 있으면 그쪽을 우선한다.
    state = {...saved, ...state};
  }

  /// 이미지를 골라 [key]의 커버로 지정한다. 골랐으면 true.
  Future<bool> pickFor(String key) async {
    final picked = await ref.read(coverImagePickerProvider).pickImage();
    if (picked == null) return false;
    final stored = await ref.read(coverStoreProvider).save(key, picked);
    state = {...state, key: stored};
    return true;
  }

  Future<void> clear(String key) async {
    state = {...state}..remove(key);
    await ref.read(coverStoreProvider).remove(key);
  }
}

final coverProvider = NotifierProvider<CoverController, Map<String, String>>(
  CoverController.new,
);

/// [key]의 커버 이미지. 없으면 null (기본 그라데이션 커버).
ImageProvider? coverImageOf(WidgetRef ref, String key) {
  final path = ref.watch(coverProvider.select((m) => m[key]));
  return path == null ? null : FileImage(File(path));
}

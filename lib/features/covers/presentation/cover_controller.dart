import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final coverImagePickerProvider = Provider<CoverImagePicker>(
  (ref) => FilePickerCoverImagePicker(),
);

/// 곡 · 재생목록 커버 이미지 (상세 기능: 커버 이미지 등록).
///
/// 지금은 앱이 켜져 있는 동안만 기억한다. 보관함 DB(drift)가 붙으면
/// 고른 파일을 앱 폴더로 복사하고 경로를 DB에 저장하도록 바꾼다.
class CoverController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  /// 이미지를 골라 [key]의 커버로 지정한다. 골랐으면 true.
  Future<bool> pickFor(String key) async {
    final path = await ref.read(coverImagePickerProvider).pickImage();
    if (path == null) return false;
    set(key, path);
    return true;
  }

  void set(String key, String path) => state = {...state, key: path};

  void clear(String key) => state = {...state}..remove(key);
}

final coverProvider = NotifierProvider<CoverController, Map<String, String>>(
  CoverController.new,
);

/// [key]의 커버 이미지. 없으면 null (기본 그라데이션 커버).
ImageProvider? coverImageOf(WidgetRef ref, String key) {
  final path = ref.watch(coverProvider.select((m) => m[key]));
  return path == null ? null : FileImage(File(path));
}

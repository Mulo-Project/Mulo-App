import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/default_music_folder.dart';
import '../../../../core/config/default_video_folder.dart';
import '../../domain/repositories/library_repository.dart';

/// 불러오는 폴더를 shared_preferences에 저장한다. 기본 저장 위치는 저장하지 않고 항상 더한다.
class PrefsLoadedFolderRepository implements LoadedFolderRepository {
  static const _key = 'library.loadedFolders';
  static const _saveKey = 'library.saveLocations';

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> watchChanges() => _changes.stream;

  @override
  String get defaultFolder => defaultMusicFolder();

  @override
  List<String> get videoFolders => videoFolderPresets();

  @override
  Future<List<String>> loadExtra() async =>
      (await SharedPreferences.getInstance()).getStringList(_key) ?? const [];

  @override
  Future<void> saveExtra(List<String> folders) async {
    await (await SharedPreferences.getInstance()).setStringList(_key, folders);
    _changes.add(null);
  }

  @override
  Future<List<String>?> loadSaveLocations() async =>
      (await SharedPreferences.getInstance()).getStringList(_saveKey);

  @override
  Future<void> saveSaveLocations(List<String> folders) async =>
      (await SharedPreferences.getInstance()).setStringList(_saveKey, folders);

  @override
  Future<String?> pickFolder() => FilePicker.getDirectoryPath();
}

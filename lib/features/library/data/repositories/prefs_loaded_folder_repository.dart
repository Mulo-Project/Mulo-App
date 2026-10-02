import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/default_music_folder.dart';
import '../../domain/repositories/library_repository.dart';

/// 불러오는 폴더를 shared_preferences에 저장한다. 기본 저장 위치는 저장하지 않고 항상 더한다.
class PrefsLoadedFolderRepository implements LoadedFolderRepository {
  static const _key = 'library.loadedFolders';

  @override
  String get defaultFolder => defaultMusicFolder();

  @override
  Future<List<String>> loadExtra() async =>
      (await SharedPreferences.getInstance()).getStringList(_key) ?? const [];

  @override
  Future<void> saveExtra(List<String> folders) async =>
      (await SharedPreferences.getInstance()).setStringList(_key, folders);

  @override
  Future<String?> pickFolder() => FilePicker.getDirectoryPath();
}

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/default_music_folder.dart';
import '../../domain/repositories/download_settings_repository.dart';

/// 기본 저장 위치를 shared_preferences에 저장한다.
class PrefsDownloadSettingsRepository implements DownloadSettingsRepository {
  static const _key = 'download.savePath';

  @override
  Future<String> loadSavePath() async =>
      (await SharedPreferences.getInstance()).getString(_key) ??
      defaultMusicFolder();

  @override
  Future<void> saveSavePath(String path) async =>
      (await SharedPreferences.getInstance()).setString(_key, path);

  @override
  Future<String?> pickFolder() => FilePicker.getDirectoryPath();
}

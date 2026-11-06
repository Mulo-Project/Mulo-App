import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/default_music_folder.dart';
import '../../../search/data/engine/audio_format_policy.dart'
    show selectableSaveFormats;
import '../../domain/entities/download_options.dart';
import '../../domain/repositories/download_settings_repository.dart';

/// 기본 저장 위치를 shared_preferences에 저장한다.
class PrefsDownloadSettingsRepository implements DownloadSettingsRepository {
  static const _key = 'download.savePath';
  static const _formatKey = 'download.format';

  @override
  List<AudioFormat> selectableFormats() => selectableSaveFormats();

  static const _lastKey = 'download.lastSavePath';

  @override
  Future<String> loadSavePath() async {
    final prefs = await SharedPreferences.getInstance();
    final fixed = prefs.getString(_key) ?? '';
    if (fixed.isNotEmpty) return fixed;
    final last = prefs.getString(_lastKey) ?? '';
    return last.isNotEmpty ? last : defaultMusicFolder();
  }

  @override
  Future<String> loadFixedSavePath() async =>
      (await SharedPreferences.getInstance()).getString(_key) ?? '';

  @override
  Future<void> saveSavePath(String path) async =>
      (await SharedPreferences.getInstance()).setString(_key, path);

  @override
  Future<void> clearSavePath() async =>
      (await SharedPreferences.getInstance()).remove(_key);

  @override
  Future<void> saveLastSavePath(String path) async =>
      (await SharedPreferences.getInstance()).setString(_lastKey, path);

  @override
  Future<AudioFormat> loadFormat() async {
    final name = (await SharedPreferences.getInstance()).getString(_formatKey);
    final formats = selectableFormats();
    final saved = AudioFormat.values.where((f) => f.name == name).firstOrNull;
    if (saved != null && formats.contains(saved)) return saved;
    return formats.contains(AudioFormat.opus)
        ? AudioFormat.opus
        : formats.firstOrNull ?? AudioFormat.opus;
  }

  @override
  Future<void> saveFormat(AudioFormat format) async =>
      (await SharedPreferences.getInstance()).setString(
        _formatKey,
        format.name,
      );

  @override
  Future<String?> pickFolder() => FilePicker.getDirectoryPath();
}

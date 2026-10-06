import 'dart:io';

import 'package:flutter/services.dart';

import '../../../library/domain/entities/loaded_folder.dart';

/// 받아서 저장한 곡 파일.
class SavedAudio {
  const SavedAudio({required this.uri, required this.folder});

  /// 재생 주소 (Android `content://`, 데스크톱 파일 경로).
  final String uri;

  /// 저장된 폴더 (불러오는 폴더 계산용).
  final String folder;
}

/// 임시 위치에 받은 오디오 파일을 사용자의 음악 폴더로 옮긴다.
abstract interface class DownloadedFileStore {
  /// [source]를 [folder] 안에 `[name].[extension]`으로 저장한다 (같은 이름이 있으면 번호를 붙인다).
  /// [source]는 저장한 뒤 지운다. 못 저장하면 예외.
  Future<SavedAudio> save(
    File source, {
    required String folder,
    required String name,
    required String extension,
    required String mime,
    required String title,
    required String artist,
  });
}

/// Android는 MediaStore(`music_app/media_store`의 `saveAudio`)로 `Music/…` 아래에 저장해
/// 기기 음악 목록에도 곧바로 나타나게 하고, 그 밖의 OS는 폴더에 파일로 복사한다.
class PlatformDownloadedFileStore implements DownloadedFileStore {
  static const _channel = MethodChannel('music_app/media_store');
  static const _androidRoot = '/storage/emulated/0/';
  static const _mediaDirs = {
    'Music',
    'Podcasts',
    'Ringtones',
    'Alarms',
    'Notifications',
    'Audiobooks',
    'Recordings',
  };

  @override
  Future<SavedAudio> save(
    File source, {
    required String folder,
    required String name,
    required String extension,
    required String mime,
    required String title,
    required String artist,
  }) async {
    if (Platform.isAndroid) {
      final relative = androidRelativePath(folder);
      final uri = await _channel.invokeMethod<String>('saveAudio', {
        'path': source.path,
        'displayName': '$name.$extension',
        'mime': mime,
        'relativePath': relative,
        'title': title,
        'artist': artist,
      });
      if (uri == null) throw const FileSystemException('저장 실패');
      await _deleteQuietly(source);
      return SavedAudio(uri: uri, folder: '$_androidRoot$relative');
    }
    final dir = Directory(folder);
    await dir.create(recursive: true);
    final target = _uniqueFile(dir, name, extension);
    try {
      await source.rename(target.path);
    } on FileSystemException {
      // 다른 드라이브면 이름 바꾸기가 안 되므로 복사한다.
      await source.copy(target.path);
      await _deleteQuietly(source);
    }
    return SavedAudio(uri: target.path, folder: normalizeFolderPath(dir.path));
  }

  /// Android 저장 폴더 → MediaStore 상대 경로. 음악 계열 폴더 밖이면 `Music/Mulo`.
  static String androidRelativePath(String folder) {
    final f = folder.replaceAll(r'\', '/');
    if (f.startsWith(_androidRoot)) {
      final rest = f
          .substring(_androidRoot.length)
          .replaceAll(RegExp(r'^/+|/+$'), '');
      if (rest.isNotEmpty && _mediaDirs.contains(rest.split('/').first)) {
        return rest;
      }
    }
    return 'Music/Mulo';
  }

  static File _uniqueFile(Directory dir, String name, String ext) {
    var file = File('${dir.path}${Platform.pathSeparator}$name.$ext');
    for (var i = 1; file.existsSync(); i++) {
      file = File('${dir.path}${Platform.pathSeparator}$name ($i).$ext');
    }
    return file;
  }

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on Object {
      // 임시 파일이라 못 지워도 괜찮다.
    }
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// opus · ogg(Vorbis 코멘트) · mp3(ID3v2.3) · mp4 · webm 파일의 태그를 ffmpeg로 쓴다.
///
/// 앱은 형식을 모르는 값 묶음(제목 · 아티스트 · 앨범 · 장르 · 가사 · 커버 PNG · 앱 전용 칸)과 파일 하나만 넘기고,
/// 형식마다 다른 키 이름 · 커버 넣는 방식은 네이티브(`TranscoderChannel`의 `tagMp3` · `tagOgg` · `tagMp4` · `tagWebm`)가 정한다.
///
/// full 빌드에 들어 있는 ffmpeg(`music_app/transcoder`의 `tag`)로 소리는 그대로(`-c copy`) 두고 태그만 다시 감싼다.
/// 이미 변환에 쓰는 ffmpeg라 새 의존이 없고, 한 번에 모든 태그를 쓴다. 다른 플레이어에서도 열리도록 ID3는 v2.3으로 쓴다.
/// ffmpeg가 없는 lite · 데스크톱은 false (lite는 서버가 태그까지 넣어 준 파일을 저장한다).
class FfmpegTagWriter {
  const FfmpegTagWriter();

  static const _channel = MethodChannel('music_app/transcoder');

  static const extensions = {'opus', 'ogg', 'mp3'};

  /// 마지막 태그 쓰기가 실패한 이유 (진단용). 성공하거나 새로 시작하면 비운다.
  static String? lastError;

  /// 이 빌드에 ffmpeg가 들어 있는지 (full 빌드 Android). lite · 데스크톱은 false.
  Future<bool> available() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// [file]의 태그를 쓴다. 쓸 값이 하나도 없으면 false. 이미 있던 태그는 두고 넘어온 칸만 바뀐다
  /// (null은 건드리지 않고, 빈 문자열은 그 칸을 지운다). 형식은 [extension]으로 정하고, 그 형식에서 값을
  /// 어떻게 쓰는지(키 이름 · 커버 방식 · 커버를 쓰는지)는 네이티브가 정한다. 못 쓰면 false (파일은 그대로).
  Future<bool> write(
    File file, {
    required String extension,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
    Uint8List? coverPng,
    Map<String, String> extra = const {},
  }) async {
    final entries = <String, String>{
      'title': ?title,
      'artist': ?artist,
      'album': ?album,
      'genre': ?genre,
      'lyrics': ?lyrics,
      // 앱이 읽어 커버 편집 상태를 되살리는 사용자 정의 태그 (COVER_SOURCE 등). 다른 플레이어는 무시한다.
      ...extra,
    };
    lastError = null;
    if (entries.isEmpty && coverPng == null) return false;
    final format = switch (extension.toLowerCase()) {
      'mp3' => 'mp3',
      'mp4' => 'mp4',
      'webm' => 'webm',
      _ => 'ogg', // opus · ogg
    };
    final meta = File('${file.path}.ffmeta');
    final out = File('${file.path}.tagged');
    final art = File('${file.path}.cover.png');
    try {
      await meta.writeAsString(ffmetadata(entries), flush: true);
      if (coverPng != null) await art.writeAsBytes(coverPng, flush: true);
      final ok = await _channel.invokeMethod<bool>('tag', {
        'input': file.path,
        'meta': meta.path,
        'output': out.path,
        'format': format,
        if (coverPng != null) 'cover': art.path,
      });
      debugPrint('MuloTag ffmpeg $format ok=$ok');
      if (ok != true || !await out.exists() || await out.length() == 0) {
        lastError ??= 'ffmpeg ok=$ok';
        debugPrint('MuloTag ffmpeg failed: $lastError');
        return false;
      }
      await out.rename(file.path);
      return true;
    } on PlatformException catch (e) {
      lastError = e.message ?? e.code;
      debugPrint('MuloTag ffmpeg error: $lastError');
      return false;
    } on MissingPluginException {
      lastError = 'no ffmpeg plugin';
      return false;
    } on FileSystemException catch (e) {
      lastError = 'file: ${e.message}';
      return false;
    } finally {
      for (final f in [meta, out, art]) {
        try {
          if (f.existsSync()) f.deleteSync();
        } on FileSystemException {
          // 임시 파일이라 못 지워도 그만.
        }
      }
    }
  }

  /// ffmpeg가 읽는 ffmetadata 텍스트. `=` `;` `#` `\` 와 줄바꿈은 앞에 `\`를 붙인다.
  @visibleForTesting
  static String ffmetadata(Map<String, String> entries) {
    String esc(String s) =>
        s.replaceAllMapped(RegExp(r'[=;#\\\n]'), (m) => '\\${m[0]}');
    final b = StringBuffer(';FFMETADATA1\n');
    entries.forEach((k, v) => b.write('$k=${esc(v)}\n'));
    return b.toString();
  }
}

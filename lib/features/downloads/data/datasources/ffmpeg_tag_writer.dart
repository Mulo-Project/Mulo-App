import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// opus · ogg(Vorbis 코멘트)와 mp3(ID3v2.3) 파일의 태그를 ffmpeg로 쓴다.
///
/// full 빌드에 들어 있는 ffmpeg(`music_app/transcoder`의 `tag`)로 소리는 그대로(`-c copy`) 두고 태그만 다시 감싼다.
/// 이미 변환에 쓰는 ffmpeg라 새 의존이 없고, 한 번에 모든 태그를 쓴다. 다른 플레이어에서도 열리도록 ID3는 v2.3으로 쓴다.
/// ffmpeg가 없는 lite · 데스크톱은 false (lite는 서버가 태그까지 넣어 준 파일을 저장한다).
class FfmpegTagWriter {
  const FfmpegTagWriter();

  static const _channel = MethodChannel('music_app/transcoder');

  static const extensions = {'opus', 'ogg', 'mp3'};

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

  /// 쓸 값이 하나도 없으면 false. 이미 있던 태그는 새 값으로 바뀐다 (빈 값은 건드리지 않는다).
  Future<bool> write(
    File audio, {
    required String extension,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
    Uint8List? coverPng,
    int coverSide = 512,
    Map<String, String> extra = const {},
  }) async {
    final mp3 = extension.toLowerCase() == 'mp3';
    final entries = <String, String>{
      if (_has(title)) 'TITLE': title!,
      if (_has(artist)) 'ARTIST': artist!,
      if (_has(album)) 'ALBUM': album!,
      if (_has(genre)) 'GENRE': genre!,
      if (_has(lyrics)) 'LYRICS': lyrics!,
      // 앱이 읽어 커버 편집 상태를 되살리는 사용자 정의 태그 (COVER_SOURCE 등). 다른 플레이어는 무시한다.
      ...extra,
      // mp3의 커버는 태그 값이 아니라 그림 파일로 따로 넘긴다.
      if (coverPng != null && !mp3)
        'METADATA_BLOCK_PICTURE': base64.encode(
          pictureBlock(coverPng, coverSide, coverSide),
        ),
    };
    if (entries.isEmpty && (coverPng == null || !mp3)) return false;
    final meta = File('${audio.path}.ffmeta');
    final out = File('${audio.path}.tagged');
    final art = File('${audio.path}.cover.png');
    try {
      await meta.writeAsString(ffmetadata(entries), flush: true);
      if (mp3 && coverPng != null) {
        await art.writeAsBytes(coverPng, flush: true);
      }
      final ok = await _channel.invokeMethod<bool>('tag', {
        'input': audio.path,
        'meta': meta.path,
        'output': out.path,
        'format': mp3 ? 'mp3' : 'ogg',
        if (mp3 && coverPng != null) 'cover': art.path,
      });
      debugPrint('MuloTag ffmpeg tag ok=$ok');
      if (ok != true || !await out.exists() || await out.length() == 0) {
        return false;
      }
      await out.rename(audio.path);
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } on FileSystemException {
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

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;

  /// ffmpeg가 읽는 ffmetadata 텍스트. `=` `;` `#` `\` 와 줄바꿈은 앞에 `\`를 붙인다.
  @visibleForTesting
  static String ffmetadata(Map<String, String> entries) {
    String esc(String s) =>
        s.replaceAllMapped(RegExp(r'[=;#\\\n]'), (m) => '\\${m[0]}');
    final b = StringBuffer(';FFMETADATA1\n');
    entries.forEach((k, v) => b.write('$k=${esc(v)}\n'));
    return b.toString();
  }

  /// Vorbis `METADATA_BLOCK_PICTURE`에 들어가는 FLAC 그림 블록 (앞면 커버, PNG).
  @visibleForTesting
  static Uint8List pictureBlock(Uint8List png, int width, int height) {
    const mime = 'image/png';
    final b = BytesBuilder();
    void u32(int v) =>
        b.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.big));
    u32(3); // 앞면 커버
    u32(mime.length);
    b.add(ascii.encode(mime));
    u32(0); // 설명 없음
    u32(width);
    u32(height);
    u32(32); // 색 깊이
    u32(0); // 색 수 (색인 없음)
    u32(png.length);
    b.add(png);
    return b.toBytes();
  }
}

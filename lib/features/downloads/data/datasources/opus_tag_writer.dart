import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// opus · ogg 파일의 태그(Vorbis 코멘트)를 ffmpeg로 쓴다.
///
/// 태그 라이브러리(`audio_metadata_reader`)가 ogg 쓰기를 지원하지 않아서, full 빌드에 들어 있는
/// ffmpeg(`music_app/transcoder`의 `tag`)로 소리는 그대로(`-c copy`) 두고 태그만 다시 감싼다.
/// ffmpeg가 없는 lite · 데스크톱은 false (lite는 서버가 태그까지 넣어 준 파일을 저장한다).
class OpusTagWriter {
  const OpusTagWriter();

  static const _channel = MethodChannel('music_app/transcoder');

  static const extensions = {'opus', 'ogg'};

  /// 쓸 값이 하나도 없으면 false. 이미 있던 태그는 새 값으로 바뀐다 (빈 값은 건드리지 않는다).
  Future<bool> write(
    File audio, {
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
    Uint8List? coverPng,
    int coverSide = 512,
  }) async {
    final entries = <String, String>{
      if (_has(title)) 'TITLE': title!,
      if (_has(artist)) 'ARTIST': artist!,
      if (_has(album)) 'ALBUM': album!,
      if (_has(genre)) 'GENRE': genre!,
      if (_has(lyrics)) 'LYRICS': lyrics!,
      if (coverPng != null)
        'METADATA_BLOCK_PICTURE': base64.encode(
          pictureBlock(coverPng, coverSide, coverSide),
        ),
    };
    if (entries.isEmpty) return false;
    final meta = File('${audio.path}.ffmeta');
    final out = File('${audio.path}.tagged');
    try {
      await meta.writeAsString(ffmetadata(entries), flush: true);
      final ok = await _channel.invokeMethod<bool>('tag', {
        'input': audio.path,
        'meta': meta.path,
        'output': out.path,
        'format': 'ogg',
      });
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
      for (final f in [meta, out]) {
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

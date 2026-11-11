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

  /// 음원(mp3 · opus · ogg)에 태그를 쓴다. 쓸 값이 하나도 없으면 false. 이미 있던 태그는 두고 넘어온 칸만 바뀐다
  /// (null은 건드리지 않고, 빈 문자열은 그 칸을 지운다). 형식별 규칙은 [FfmpegFormatWriter]가 갖는다.
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
  }) => _run(
    audio,
    FfmpegFormatWriter.forExtension(extension) ?? const OggFormatWriter(),
    TagValues(
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      lyrics: lyrics,
      coverPng: coverPng,
      coverSide: coverSide,
      extra: extra,
    ),
  );

  /// 영상 파일(mp4 · webm)에 태그를 쓴다 (영상 · 소리는 그대로). mp4는 [coverPng]를 첨부 그림으로 붙이고,
  /// webm은 첨부 그림을 쓸 수 없어 글 태그만 쓴다. 쓸 값이 없거나 못 쓰면 false (파일은 그대로).
  Future<bool> writeVideo(
    File video, {
    required String extension,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
    Uint8List? coverPng,
    Map<String, String> extra = const {},
  }) => _run(
    video,
    FfmpegFormatWriter.forExtension(extension) ?? const WebmFormatWriter(),
    TagValues(
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      lyrics: lyrics,
      coverPng: coverPng,
      extra: extra,
    ),
  );

  /// 형식 [writer]의 규칙대로 [file]의 태그를 쓴다 (임시 파일 만들기 → ffmpeg → 바꿔치기). 형식마다 다른 것은 모두 [writer]에 있다.
  Future<bool> _run(
    File file,
    FfmpegFormatWriter writer,
    TagValues values,
  ) async {
    final entries = writer.entries(values);
    final cover = writer.coverAsFile ? values.coverPng : null;
    lastError = null;
    if (entries.isEmpty && cover == null) return false;
    final meta = File('${file.path}.ffmeta');
    final out = File('${file.path}.tagged');
    final art = File('${file.path}.cover.png');
    try {
      await meta.writeAsString(ffmetadata(entries), flush: true);
      if (cover != null) await art.writeAsBytes(cover, flush: true);
      final ok = await _channel.invokeMethod<bool>(writer.method, {
        'input': file.path,
        'meta': meta.path,
        'output': out.path,
        'format': writer.format,
        if (cover != null) 'cover': art.path,
      });
      debugPrint('MuloTag ffmpeg ${writer.format} ok=$ok');
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

/// 쓸 태그 값 묶음. null은 그 칸을 건드리지 않는다는 뜻이다.
class TagValues {
  const TagValues({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.lyrics,
    this.coverPng,
    this.coverSide = 512,
    this.extra = const {},
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? lyrics;
  final Uint8List? coverPng;
  final int coverSide;

  /// 앱이 읽어 커버 편집 상태를 되살리는 사용자 정의 태그 (COVER_SOURCE 등). 다른 플레이어는 무시한다.
  final Map<String, String> extra;
}

/// 형식 하나의 ffmpeg 태그 쓰기 규칙. 형식마다 구현이 따로 있어 한 형식의 규칙을 바꿔도 다른 형식에 영향이 없다.
/// 실제 ffmpeg 인자는 네이티브(`TranscoderChannel`)의 같은 형식 함수가 만든다.
abstract interface class FfmpegFormatWriter {
  /// 네이티브 호출 이름: 음원 `tag`, 영상 `tagVideo`.
  String get method;

  /// 네이티브에 넘기는 형식 이름.
  String get format;

  /// 커버를 그림 파일로 따로 넘기는가 (아니면 태그 값 안에 넣거나 커버를 쓰지 않는다).
  bool get coverAsFile;

  /// 이 형식에 쓸 칸들 (키 이름 · 커버 표현이 형식마다 다르다).
  Map<String, String> entries(TagValues values);

  /// [extension]을 처리하는 형식 (없으면 null).
  static FfmpegFormatWriter? forExtension(String extension) =>
      switch (extension.toLowerCase()) {
        'mp3' => const Mp3FormatWriter(),
        'opus' || 'ogg' => const OggFormatWriter(),
        'mp4' => const Mp4FormatWriter(),
        'webm' => const WebmFormatWriter(),
        _ => null,
      };
}

/// mp3(ID3v2.3): 대문자 키, 커버는 첨부 그림 파일.
class Mp3FormatWriter implements FfmpegFormatWriter {
  const Mp3FormatWriter();

  @override
  String get method => 'tag';

  @override
  String get format => 'mp3';

  @override
  bool get coverAsFile => true;

  @override
  Map<String, String> entries(TagValues v) => {
    'TITLE': ?v.title,
    'ARTIST': ?v.artist,
    'ALBUM': ?v.album,
    'GENRE': ?v.genre,
    'LYRICS': ?v.lyrics,
    ...v.extra,
  };
}

/// opus · ogg(Vorbis 코멘트): 대문자 키, 커버는 `METADATA_BLOCK_PICTURE` 태그 값.
class OggFormatWriter implements FfmpegFormatWriter {
  const OggFormatWriter();

  @override
  String get method => 'tag';

  @override
  String get format => 'ogg';

  @override
  bool get coverAsFile => false;

  @override
  Map<String, String> entries(TagValues v) => {
    'TITLE': ?v.title,
    'ARTIST': ?v.artist,
    'ALBUM': ?v.album,
    'GENRE': ?v.genre,
    'LYRICS': ?v.lyrics,
    ...v.extra,
    if (v.coverPng != null)
      'METADATA_BLOCK_PICTURE': base64.encode(
        FfmpegTagWriter.pictureBlock(v.coverPng!, v.coverSide, v.coverSide),
      ),
  };
}

/// mp4 영상: 소문자 키, 커버는 첨부 그림 파일.
class Mp4FormatWriter implements FfmpegFormatWriter {
  const Mp4FormatWriter();

  @override
  String get method => 'tagVideo';

  @override
  String get format => 'mp4';

  @override
  bool get coverAsFile => true;

  @override
  Map<String, String> entries(TagValues v) => {
    'title': ?v.title,
    'artist': ?v.artist,
    'album': ?v.album,
    'genre': ?v.genre,
    'lyrics': ?v.lyrics,
    ...v.extra,
  };
}

/// webm(Matroska) 영상: 소문자 키, 첨부 그림을 쓰지 않는다 (글 태그만).
class WebmFormatWriter implements FfmpegFormatWriter {
  const WebmFormatWriter();

  @override
  String get method => 'tagVideo';

  @override
  String get format => 'webm';

  @override
  bool get coverAsFile => false;

  @override
  Map<String, String> entries(TagValues v) => {
    'title': ?v.title,
    'artist': ?v.artist,
    'album': ?v.album,
    'genre': ?v.genre,
    'lyrics': ?v.lyrics,
    ...v.extra,
  };
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../covers/domain/entities/cover_art.dart';

/// 네이티브가 태그를 쓴 결과.
enum NativeTagStatus {
  /// 파일에 썼다.
  written,

  /// 쓰려다 실패했다 (이유는 [NativeTags.lastError]).
  failed,

  /// 파일을 쓸 권한이 없다 (Android 동의 창을 거절했거나 못 띄움).
  denied,

  /// 태그를 쓰지 않는 곡이다 (모르는 형식 · ffmpeg 없는 빌드 · 파일 없음).
  unsupported,
}

/// 곡 파일의 태그 읽기 · 쓰기 (`music_app/tags`).
///
/// Dart는 **형식을 모른다**. 형식을 모르는 값(제목 · 아티스트 · 앨범 · 장르 · 가사 · 앱 전용 칸)과 커버 이미지 경로 ·
/// 파일 하나(`content://` 주소 또는 경로)만 호출 하나로 넘기고, 형식 구분 · 복사 · 태그 쓰기 · 덮어쓰기 · 동의 창은
/// 네이티브(`TagChannel`)가 한다.
class NativeTags {
  const NativeTags();

  static const _channel = MethodChannel('music_app/tags');

  /// 마지막 태그 쓰기가 실패한 이유 (진단용). 성공하거나 새로 시작하면 비운다.
  static String? lastError;

  /// [target]의 태그를 쓴다. [values]는 `title` `artist` `album` `genre` `lyrics`와 앱 전용 칸이고,
  /// 이미 있던 태그는 두고 넘어온 칸만 바뀐다. [cover]는 원본 이미지 파일과 고른 확대 · 위치 · 각도다
  /// (정사각형으로 자르는 것도 네이티브가 한다). [extension]은 경로 파일의 확장자 힌트다.
  Future<NativeTagStatus> write(
    String target, {
    Map<String, String> values = const {},
    ({String path, CoverTransform transform})? cover,
    String? extension,
    bool ask = false,
  }) async {
    lastError = null;
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('write', {
        'uri': target,
        'extension': extension,
        'values': values,
        if (cover != null)
          'cover': {
            'path': cover.path,
            'scale': cover.transform.scale,
            'dx': cover.transform.dx,
            'dy': cover.transform.dy,
            'rotation': cover.transform.rotation,
          },
        'ask': ask,
      });
      final status = switch (r?['status']) {
        'written' => NativeTagStatus.written,
        'denied' => NativeTagStatus.denied,
        'unsupported' => NativeTagStatus.unsupported,
        _ => NativeTagStatus.failed,
      };
      if (status == NativeTagStatus.failed) {
        lastError = (r?['error'] as String?) ?? 'unknown';
      }
      debugPrint('MuloTag write ${status.name} ${lastError ?? ''}');
      return status;
    } on PlatformException catch (e) {
      lastError = e.message ?? e.code;
      return NativeTagStatus.failed;
    } on MissingPluginException {
      lastError = 'no tag plugin';
      return NativeTagStatus.unsupported;
    }
  }

  /// [target]의 태그를 읽는다. `status`는 `ok` · `unsupported` · `failed`, 키는 소문자.
  Future<({String status, Map<String, String> tags})> read(
    String target, {
    String? extension,
  }) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('read', {
        'uri': target,
        'extension': extension,
      });
      final tags = (r?['tags'] as Map?)?.map(
        (k, v) => MapEntry('$k', '$v'),
      );
      return (status: (r?['status'] as String?) ?? 'failed', tags: tags ?? {});
    } on PlatformException {
      return (status: 'failed', tags: <String, String>{});
    } on MissingPluginException {
      return (status: 'unsupported', tags: <String, String>{});
    }
  }

  /// 곡 파일에 쓸 수 있는지 확인하고, 못 쓰면 [ask]일 때 시스템 동의 창을 띄운다.
  /// 파일에 쓰지 않는 곡은 물을 것이 없어 true.
  Future<bool> ensure(String uri, {bool ask = true}) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('ensure', {
        'uri': uri,
        'ask': ask,
      });
      return (r?['ok'] as bool?) ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }
}

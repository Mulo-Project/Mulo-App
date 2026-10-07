import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/entities/download_options.dart';
import 'audio_file_downloader.dart';

/// 받은 오디오를 다른 형식 · 음질로 바꾼다.
///
/// 어떤 변환이 필요한지는 [plan]이 정한다 (순수 계산). 변환기가 없거나 실패하면 [convert]가 null을 돌려주고,
/// 받는 쪽은 받은 원본 그대로 저장한다 (받은 곡을 잃지 않도록).
abstract interface class AudioTranscoder {
  /// 이 기기에서 변환할 수 있는지 (Android full 빌드만).
  Future<bool> isAvailable();

  /// [source]를 [plan]대로 [target]에 바꿔 쓴다. 못 하면 null.
  Future<DownloadedAudio?> convert(
    DownloadedAudio source,
    TranscodePlan plan,
    File target,
  );

  /// 돌고 있는 변환을 멈춘다.
  Future<void> cancel();
}

/// 변환 방법 하나: 코덱 · 비트레이트 · 결과 확장자 · 형식.
class TranscodePlan {
  const TranscodePlan(this.codec, this.bitrateKbps, this.extension, this.mime);

  /// ffmpeg 코덱 이름 (`libmp3lame` · `libopus`).
  final String codec;
  final int bitrateKbps;
  final String extension;
  final String mime;

  /// 저장 형식 · 음질에서 변환 방법을 정한다. 원본을 그대로 두면 null.
  ///
  /// - mp3: 항상 변환 (최고 192 · 보통 128 · 절약 96 kbps).
  /// - opus: 최고는 받은 원본 그대로, 보통 · 절약은 opus로 다시 인코딩 (96 · 64 kbps).
  /// - m4a: 변환하지 않는다 (Apple 기기는 원본이 이미 m4a다).
  static TranscodePlan? of(AudioFormat format, Quality quality) =>
      switch ((format, quality)) {
        (AudioFormat.mp3, Quality.best) => const TranscodePlan(
          'libmp3lame',
          192,
          'mp3',
          'audio/mpeg',
        ),
        (AudioFormat.mp3, Quality.normal) => const TranscodePlan(
          'libmp3lame',
          128,
          'mp3',
          'audio/mpeg',
        ),
        (AudioFormat.mp3, Quality.saver) => const TranscodePlan(
          'libmp3lame',
          96,
          'mp3',
          'audio/mpeg',
        ),
        (AudioFormat.opus, Quality.normal) => const TranscodePlan(
          'libopus',
          96,
          'opus',
          'audio/ogg',
        ),
        (AudioFormat.opus, Quality.saver) => const TranscodePlan(
          'libopus',
          64,
          'opus',
          'audio/ogg',
        ),
        _ => null,
      };
}

/// Android 네이티브 변환기(`music_app/transcoder`): full 빌드에 들어 있는 ffmpeg를 실행한다.
/// 그 밖의 OS · lite 빌드는 쓸 수 없다.
class PlatformAudioTranscoder implements AudioTranscoder {
  PlatformAudioTranscoder({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/transcoder');

  final MethodChannel _channel;
  bool? _available;

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      return _available ??=
          await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return _available = false;
    } on MissingPluginException {
      return _available = false;
    }
  }

  @override
  Future<DownloadedAudio?> convert(
    DownloadedAudio source,
    TranscodePlan plan,
    File target,
  ) async {
    if (!await isAvailable()) return null;
    try {
      final ok = await _channel.invokeMethod<bool>('convert', {
        'input': source.file.path,
        'output': target.path,
        'codec': plan.codec,
        'bitrate': plan.bitrateKbps,
        'format': plan.extension == 'mp3' ? 'mp3' : 'ogg',
      });
      if (ok != true || !await target.exists() || await target.length() == 0) {
        return null;
      }
      return DownloadedAudio(target, plan.extension, plan.mime);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> cancel() async {
    if (!await isAvailable()) return;
    try {
      await _channel.invokeMethod<void>('cancel');
    } on PlatformException {
      // 이미 끝났다.
    }
  }
}

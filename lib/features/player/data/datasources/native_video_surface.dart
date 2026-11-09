import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/video_surface_info.dart';
import '../../domain/repositories/video_surface.dart';

/// 영상 화면을 Android 네이티브(`VideoChannel`)에서 텍스처로 받는다.
/// 네이티브 → Dart: `size`(width, height) · `ready`(value) · `pip`(value, 작은 창 여부).
class NativeVideoSurface implements VideoSurface {
  NativeVideoSurface({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/video') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final _events = StreamController<VideoSurfaceEvent>.broadcast();

  Future<void> _onCall(MethodCall call) async {
    final args = call.arguments;
    switch (call.method) {
      case 'size':
        if (args is Map) {
          _events.add(
            VideoSurfaceEvent(
              width: (args['width'] as num).toInt(),
              height: (args['height'] as num).toInt(),
            ),
          );
        }
      case 'ready':
        if (args is Map) {
          _events.add(VideoSurfaceEvent(ready: args['value'] as bool));
        }
      case 'pip':
        if (args is Map) {
          _events.add(VideoSurfaceEvent(pip: args['value'] as bool));
        }
    }
  }

  @override
  Future<VideoSurfaceInfo?> attach() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('attach');
      if (m == null) return null;
      return VideoSurfaceInfo(
        textureId: (m['id'] as num).toInt(),
        ready: m['ready'] as bool? ?? false,
        width: (m['width'] as num?)?.toInt() ?? 0,
        height: (m['height'] as num?)?.toInt() ?? 0,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // 네이티브가 없는 환경(테스트 · 다른 OS)은 영상 없이 간다.
      return null;
    }
  }

  @override
  Future<void> detach() async {
    try {
      await _channel.invokeMethod<void>('detach');
    } on PlatformException {
      // 이미 정리됐으면 그만.
    } on MissingPluginException {
      // 네이티브가 없으면 할 일이 없다.
    }
  }

  @override
  Stream<VideoSurfaceEvent> watch() => _events.stream;
}

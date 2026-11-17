import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/repositories/app_session_repository.dart';

/// 네이티브(`music_app/app_session`)가 보내는 "화면이 새로 열림" 신호를 받는다.
class AppSessionChannel implements AppSessionRepository {
  AppSessionChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/app_session') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'relaunched') _relaunch.add(null);
    });
  }

  final MethodChannel _channel;
  final _relaunch = StreamController<void>.broadcast();

  @override
  Stream<void> watchRelaunch() => _relaunch.stream;
}

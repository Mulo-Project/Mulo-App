import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/notification_settings_repository.dart';

/// 알림 설정을 shared_preferences에, 시스템 알림 권한은 permission_handler로 다룬다.
class PrefsNotificationSettingsRepository
    implements NotificationSettingsRepository {
  static const _progress = 'notification.downloadProgress';
  static const _result = 'notification.downloadResult';
  static const _playback = 'notification.playback';
  static const _hide = 'notification.hideSongInfo';
  static const _background = 'notification.backgroundDownload';

  /// 알림 권한이 따로 있는 OS (Android 13+ · iOS). 데스크톱은 늘 허용으로 본다.
  bool get _needsPermission => Platform.isAndroid || Platform.isIOS;

  @override
  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      downloadProgress: prefs.getBool(_progress) ?? true,
      downloadResult: prefs.getBool(_result) ?? true,
      playback: prefs.getBool(_playback) ?? true,
      hideSongInfo: prefs.getBool(_hide) ?? false,
      backgroundDownload: prefs.getBool(_background) ?? true,
    );
  }

  @override
  Future<void> save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_progress, settings.downloadProgress);
    await prefs.setBool(_result, settings.downloadResult);
    await prefs.setBool(_playback, settings.playback);
    await prefs.setBool(_hide, settings.hideSongInfo);
    await prefs.setBool(_background, settings.backgroundDownload);
  }

  @override
  Future<bool> isPermissionGranted() async {
    if (!_needsPermission) return true;
    return Permission.notification.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_needsPermission) return true;
    return (await Permission.notification.request()).isGranted;
  }

  @override
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}

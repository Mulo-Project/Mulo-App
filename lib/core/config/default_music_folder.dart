import 'dart:io';

/// 받은 곡을 모으는 기본 폴더 (Android `Music/Mulo`, 데스크톱 사용자 폴더의 `Music/Mulo`).
String defaultMusicFolder() {
  if (Platform.isAndroid) return '/storage/emulated/0/Music/Mulo';
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  return '${(home ?? '').replaceAll(r'\', '/')}/Music/Mulo';
}

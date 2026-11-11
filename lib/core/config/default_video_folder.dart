import 'dart:io';

/// 영상 파일을 모으는 기본 폴더 (Android `Movies/Mulo`). 영상 저장은 Android 전용이다.
String defaultVideoFolder() =>
    Platform.isAndroid ? '/storage/emulated/0/Movies/Mulo' : '';

/// 영상 저장 위치로 고를 수 있는 기본 폴더들: 앱 폴더 · 영화 · 다운로드.
/// (MediaStore가 영상을 받아 주는 위치만 둔다.)
List<String> videoFolderPresets() => Platform.isAndroid
    ? const [
        '/storage/emulated/0/Movies/Mulo',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Download',
      ]
    : const [];

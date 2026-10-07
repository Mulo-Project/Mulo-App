import 'dart:io';

/// 빌드 때 정해지는 값. 앱 안에서 바꾸지 않는다 (D-029).
///
/// 서버는 개발자가 배포한 하나뿐이라 주소를 빌드에 넣는다:
/// `flutter run --dart-define=MULO_API_BASE_URL=https://api.example.com`
class AppConfig {
  const AppConfig._();

  /// Mulo 서버 주소. 비어 있으면 서버 모드를 쓸 수 없다.
  static const String apiBaseUrl = String.fromEnvironment(
    'MULO_API_BASE_URL',
    defaultValue: '',
  );

  /// 서버 주소가 빌드에 들어 있는지.
  static bool get hasApiBaseUrl => apiBaseUrl.isNotEmpty;

  /// 구글 로그인용 웹 클라이언트 ID (Google Cloud의 "웹 애플리케이션" OAuth 클라이언트).
  /// 비밀값이 아니라 공개 ID지만 저장소에는 넣지 않고 빌드에 넣는다:
  /// `--dart-define=MULO_GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
  static const String googleServerClientId = String.fromEnvironment(
    'MULO_GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// 구글 클라이언트 ID가 빌드에 들어 있는지 (없으면 Android 로그인을 쓸 수 없다).
  static bool get hasGoogleClient => googleServerClientId.isNotEmpty;

  /// 데스크톱 구글 로그인용 "데스크톱 앱" OAuth 클라이언트 ID · 비밀값.
  /// 구글이 데스크톱 클라이언트에도 비밀값을 요구하지만 앱에 들어가는 값이라 비밀로 지켜지지는
  /// 않는다 (PKCE가 코드를 지킨다). 저장소에는 넣지 않고 빌드에 넣는다:
  /// `--dart-define=MULO_GOOGLE_DESKTOP_CLIENT_ID=... --dart-define=MULO_GOOGLE_DESKTOP_CLIENT_SECRET=...`
  static const String googleDesktopClientId = String.fromEnvironment(
    'MULO_GOOGLE_DESKTOP_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleDesktopClientSecret = String.fromEnvironment(
    'MULO_GOOGLE_DESKTOP_CLIENT_SECRET',
    defaultValue: '',
  );

  /// 이 기기에서 구글 로그인을 쓰려면 빌드에 넣어야 하는 dart-define 이름 (안내 문구용).
  static String get googleRequiredKeys => Platform.isAndroid
      ? 'MULO_GOOGLE_SERVER_CLIENT_ID'
      : 'MULO_GOOGLE_DESKTOP_CLIENT_ID · MULO_GOOGLE_DESKTOP_CLIENT_SECRET';

  static bool get hasGoogleDesktopClient =>
      googleDesktopClientId.isNotEmpty && googleDesktopClientSecret.isNotEmpty;
}

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
}

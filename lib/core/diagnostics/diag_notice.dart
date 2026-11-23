import 'dart:async';

/// 임시 진단 알림: 로그가 잘 안 보이는 기기에서 원인을 찾을 때 디버그 빌드가 snackbar로 보여 주는 한 줄.
/// 원인 확인이 끝나면 쓰는 곳과 함께 지운다.
abstract final class DiagNotice {
  static final _controller = StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  static void post(String message) {
    if (!_controller.isClosed) _controller.add(message);
  }
}

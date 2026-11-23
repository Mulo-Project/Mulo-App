/// 유스케이스 공통 규약: 동작 하나 = 클래스 하나, `call()`로 실행한다.
///
/// domain 계층은 순수 Dart만 쓴다 (Flutter · 플러그인 · DB import 금지).
abstract interface class UseCase<Result, Params> {
  Future<Result> call(Params params);
}

/// 흐름(Stream)을 돌려주는 유스케이스 (DB 변경 구독 등).
abstract interface class StreamUseCase<Result, Params> {
  Stream<Result> call(Params params);
}

/// 매개변수가 없는 유스케이스용.
final class NoParams {
  const NoParams();
}

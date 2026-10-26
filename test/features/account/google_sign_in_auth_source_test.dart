import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:music_download_play_app/features/account/data/datasources/google_sign_in_auth_source.dart';
import 'package:music_download_play_app/features/account/data/datasources/loopback_google_auth.dart';

class _MemoryStore implements AuthStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

const _result = AuthenticationResults(
  user: GoogleSignInUserData(email: 'me@example.com', id: 'u1'),
  authenticationTokens: AuthenticationTokenData(idToken: 'id'),
);

class _FakePlatform extends GoogleSignInPlatform {
  /// 가벼운 로그인이 돌려줄 계정 (null이면 되살릴 계정 없음).
  AuthenticationResults? lightweight = _result;
  bool lightweightThrows = false;
  int lightweightCalls = 0;
  int signOuts = 0;

  @override
  Future<void> init(InitParameters params) async {}

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) async {
    lightweightCalls++;
    if (lightweightThrows) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );
    }
    return lightweight;
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async => _result;

  @override
  Future<void> signOut(SignOutParams params) async => signOuts++;

  @override
  Future<void> disconnect(DisconnectParams params) async {}

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;
}

void main() {
  late _FakePlatform platform;
  late _MemoryStore store;
  late GoogleSignInAuthSource source;

  setUp(() {
    platform = _FakePlatform();
    GoogleSignInPlatform.instance = platform;
    store = _MemoryStore();
    source = GoogleSignInAuthSource(store: store);
  });

  test('로그인한 적 없으면 복원하지 않고 구글을 부르지도 않는다 (창이 뜨지 않는다)', () async {
    expect(await source.restore(), isNull);
    expect(platform.lightweightCalls, 0);
  });

  test('로그인에 성공하면 표시를 남기고, 다시 켜면 조용히 되살린다', () async {
    await source.signIn();
    expect(store.values, isNotEmpty);

    final again = GoogleSignInAuthSource(store: store);
    final account = await again.restore();
    expect(account?.email, 'me@example.com');
    expect(platform.lightweightCalls, 1);
  });

  test('로그아웃하면 표시를 지워 다시 켜도 복원하지 않는다', () async {
    await source.signIn();
    await source.signOut();
    expect(store.values, isEmpty);

    expect(await GoogleSignInAuthSource(store: store).restore(), isNull);
    expect(platform.lightweightCalls, 0);
  });

  test('되살릴 계정이 없으면 표시를 지워 다음부터는 시도하지 않는다', () async {
    await source.signIn();
    platform.lightweight = null;

    expect(await GoogleSignInAuthSource(store: store).restore(), isNull);
    expect(store.values, isEmpty);
    expect(await GoogleSignInAuthSource(store: store).restore(), isNull);
    expect(platform.lightweightCalls, 1);
  });

  test('일시적 오류면 로그아웃 상태로 시작하되 표시는 남긴다', () async {
    await source.signIn();
    platform.lightweightThrows = true;

    expect(await GoogleSignInAuthSource(store: store).restore(), isNull);
    expect(store.values, isNotEmpty);
  });
}

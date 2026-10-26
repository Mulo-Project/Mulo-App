import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/google_account.dart';
import 'google_auth_source.dart';
import 'loopback_google_auth.dart' show AuthStore, SecureAuthStore;

/// Android: `google_sign_in`(Credential Manager)로 로그인한다.
class GoogleSignInAuthSource implements GoogleAuthSource {
  GoogleSignInAuthSource({GoogleSignIn? signIn, AuthStore? store})
    : _google = signIn ?? GoogleSignIn.instance,
      _store = store ?? const SecureAuthStore();

  static const _scopes = [youtubeReadonlyScope];

  /// 이 앱에서 로그인에 성공했고 아직 로그아웃하지 않았다는 표시 (D-081).
  static const _signedInKey = 'account.google.signedIn';

  final GoogleSignIn _google;
  final AuthStore _store;
  Future<void>? _init;
  GoogleSignInAccount? _account;

  Future<void> _ready() => _init ??= _google.initialize(
    serverClientId: AppConfig.googleServerClientId,
  );

  GoogleAccount _map(GoogleSignInAccount a) => GoogleAccount(
    id: a.id,
    email: a.email,
    displayName: a.displayName,
    photoUrl: a.photoUrl,
  );

  @override
  Future<GoogleAccount?> restore() async {
    // 이 앱으로 로그인한 표시가 있을 때만 조용히 되살린다. 표시 없이 부르면 구글이
    // 기기의 계정 고르기 창을 저절로 띄울 수 있다 (D-079, D-081).
    try {
      if (await _store.read(_signedInKey) == null) return null;
      await _ready();
      final a = await _google.attemptLightweightAuthentication();
      if (a == null) {
        // 되살릴 수 없으면 표시를 지워 다음 실행부터는 시도하지 않는다.
        await _store.delete(_signedInKey);
        return null;
      }
      _account = a;
      return _map(a);
    } on Object {
      // 네트워크 등 일시적 실패: 로그아웃 상태로 시작하되 표시는 남겨 다음에 다시 시도한다.
      return null;
    }
  }

  @override
  Future<GoogleAccount> signIn() async {
    await _ready();
    try {
      final a = await _google.authenticate(scopeHint: _scopes);
      _account = a;
      await _markSignedIn();
      return _map(a);
    } on GoogleSignInException catch (e) {
      throw AccountException(switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable => AccountFailure.cancelled,
        _ => AccountFailure.failed,
      }, '${e.code}');
    }
  }

  @override
  Future<void> signOut() async {
    _account = null;
    await _forget();
    await _ready();
    await _google.signOut();
  }

  Future<void> _markSignedIn() async {
    try {
      await _store.write(_signedInKey, '1');
    } on Object {
      // 저장하지 못하면 이번 실행에서만 로그인 상태다.
    }
  }

  Future<void> _forget() async {
    try {
      await _store.delete(_signedInKey);
    } on Object {
      // 지우지 못해도 로그아웃은 계속한다.
    }
  }

  /// 이미 허락했으면 조용히, 아니면 허락 창을 띄운다.
  @override
  Future<String> accessToken() async {
    final account = _account;
    if (account == null) {
      throw const AccountException(AccountFailure.unauthorized);
    }
    try {
      final client = account.authorizationClient;
      final auth =
          await client.authorizationForScopes(_scopes) ??
          await client.authorizeScopes(_scopes);
      return auth.accessToken;
    } on GoogleSignInException catch (e) {
      throw AccountException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AccountFailure.cancelled
            : AccountFailure.unauthorized,
        '${e.code}',
      );
    }
  }
}

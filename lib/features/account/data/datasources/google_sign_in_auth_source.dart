import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/google_account.dart';
import 'google_auth_source.dart';

/// Android: `google_sign_in`(Credential Manager)로 로그인한다.
class GoogleSignInAuthSource implements GoogleAuthSource {
  GoogleSignInAuthSource({GoogleSignIn? signIn})
    : _google = signIn ?? GoogleSignIn.instance;

  static const _scopes = [youtubeReadonlyScope];

  final GoogleSignIn _google;
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
    try {
      await _ready();
      final a =
          await (_google.attemptLightweightAuthentication() ??
              Future<GoogleSignInAccount?>.value());
      _account = a;
      return a == null ? null : _map(a);
    } on Object {
      // 되살리지 못하면 로그아웃 상태로 둔다 (설정에서 다시 로그인).
      return null;
    }
  }

  @override
  Future<GoogleAccount> signIn() async {
    await _ready();
    try {
      final a = await _google.authenticate(scopeHint: _scopes);
      _account = a;
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
    await _ready();
    await _google.signOut();
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

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
    // 앱을 켤 때 `attemptLightweightAuthentication`을 부르면 구글 로그인 창이 저절로 뜰 수
    // 있어서 부르지 않는다. 로그인은 사용자가 관련 버튼을 눌렀을 때만 띄운다 (D-079).
    return null;
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

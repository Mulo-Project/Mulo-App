import '../../domain/entities/google_account.dart';

/// 구글 로그인 한 가지 방식 (Android: `google_sign_in`, 데스크톱: 브라우저 로그인).
/// 실패는 [AccountException]으로 던진다.
abstract interface class GoogleAuthSource {
  /// 이전 로그인을 되살린다. 없거나 못 되살리면 null.
  Future<GoogleAccount?> restore();

  /// 로그인한다 (유튜브 읽기 권한 포함).
  Future<GoogleAccount> signIn();

  Future<void> signOut();

  /// 유튜브 읽기 권한이 든 접근 토큰.
  Future<String> accessToken();
}

/// 유튜브 재생목록을 읽는 데 쓰는 권한 (읽기 전용).
const youtubeReadonlyScope = 'https://www.googleapis.com/auth/youtube.readonly';

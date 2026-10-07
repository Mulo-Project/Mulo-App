import 'package:equatable/equatable.dart';

/// 로그인한 구글 계정 (앱이 아는 것은 표시용 정보뿐이다).
class GoogleAccount extends Equatable {
  const GoogleAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// 화면에 보일 이름 (이름이 없으면 이메일).
  String get label => (displayName ?? '').isEmpty ? email : displayName!;

  @override
  List<Object?> get props => [id, email, displayName, photoUrl];
}

/// 계정 로그인을 쓸 수 있는지.
enum AccountSupport {
  available,

  /// 빌드에 구글 클라이언트 ID가 없다 (`MULO_GOOGLE_SERVER_CLIENT_ID`).
  notConfigured,

  /// 이 기기(데스크톱 등)에서는 구글 로그인을 지원하지 않는다.
  unsupportedPlatform,
}

enum AccountFailure {
  unsupported,
  cancelled,
  network,

  /// 로그인이 풀렸거나 유튜브 읽기 권한이 없다.
  unauthorized,

  /// 이 구글 계정에는 유튜브 채널이 없다 (재생목록 API는 채널의 것만 읽는다).
  noChannel,
  failed,
}

class AccountException implements Exception {
  const AccountException(this.failure, [this.message = '']);

  final AccountFailure failure;
  final String message;

  @override
  String toString() => 'AccountException($failure, $message)';
}

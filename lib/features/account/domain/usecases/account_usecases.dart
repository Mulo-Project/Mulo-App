import '../../../../core/usecase/usecase.dart';
import '../../../search/domain/entities/media_info.dart';
import '../entities/google_account.dart';
import '../repositories/account_repository.dart';

/// 로그인 가능 여부 (이 기기 · 이 빌드).
class GetAccountSupport implements UseCase<AccountSupport, NoParams> {
  const GetAccountSupport(this._repo);

  final AccountRepository _repo;

  @override
  Future<AccountSupport> call(NoParams params) async => _repo.support;
}

/// 앱을 열 때 이전 로그인 되살리기.
class RestoreAccount implements UseCase<GoogleAccount?, NoParams> {
  const RestoreAccount(this._repo);

  final AccountRepository _repo;

  @override
  Future<GoogleAccount?> call(NoParams params) => _repo.restore();
}

class SignInAccount implements UseCase<GoogleAccount, NoParams> {
  const SignInAccount(this._repo);

  final AccountRepository _repo;

  @override
  Future<GoogleAccount> call(NoParams params) => _repo.signIn();
}

class SignOutAccount implements UseCase<void, NoParams> {
  const SignOutAccount(this._repo);

  final AccountRepository _repo;

  @override
  Future<void> call(NoParams params) => _repo.signOut();
}

/// 내 유튜브 재생목록 불러오기 (상세 기능: 유튜브 재생목록 가져오기 #22).
class FetchMyPlaylists implements UseCase<List<PlaylistHit>, NoParams> {
  const FetchMyPlaylists(this._repo);

  final AccountRepository _repo;

  @override
  Future<List<PlaylistHit>> call(NoParams params) => _repo.myPlaylists();
}

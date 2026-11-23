import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/account/domain/entities/google_account.dart';
import 'package:music_download_play_app/features/account/domain/usecases/account_usecases.dart';
import 'package:music_download_play_app/features/account/presentation/bloc/account_cubit.dart';
import 'package:music_download_play_app/features/downloads/domain/usecases/download_usecases.dart';
import 'package:music_download_play_app/features/playlists/domain/usecases/playlist_usecases.dart';
import 'package:music_download_play_app/features/playlists/presentation/bloc/playlist_import_cubit.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';

import '../../helpers/fakes.dart';

AccountCubit _accountCubit(FakeAccountRepository repo) => AccountCubit(
  GetAccountSupport(repo),
  RestoreAccount(repo),
  SignInAccount(repo),
  SignOutAccount(repo),
);

PlaylistImportCubit _importCubit(FakeAccountRepository repo) {
  final engine = FakeDownloaderEngine();
  final queue = MemoryDownloadQueue();
  final lists = MemoryPlaylistRepository();
  return PlaylistImportCubit(
    FetchMediaInfo(engine),
    SearchPlaylists(engine),
    FetchMyPlaylists(repo),
    EnqueueDownload(queue),
    CreatePlaylist(lists),
    FindExistingDownload(queue),
    AddTracksToPlaylist(lists),
    FetchChannelPlaylists(repo),
  );
}

void main() {
  group('AccountCubit', () {
    test('이전 로그인을 되살리고, 로그인 · 로그아웃을 바꾼다', () async {
      final repo = FakeAccountRepository(
        account: const GoogleAccount(id: 'u', email: 'a@b.c'),
      );
      final cubit = _accountCubit(repo);
      await cubit.load();
      expect(cubit.state.signedIn, isTrue);
      await cubit.signOut();
      expect(cubit.state.signedIn, isFalse);
      expect(await cubit.signIn(), isNotNull);
      expect(cubit.state.signedIn, isTrue);
    });

    test('로그인을 취소하면 실패로 치지 않고, 실패하면 까닭을 남긴다', () async {
      final cancelled = _accountCubit(
        FakeAccountRepository(
          signInError: const AccountException(AccountFailure.cancelled),
        ),
      );
      expect(await cancelled.signIn(), isNull);
      expect(cancelled.state.failure, isNull);

      final failed = _accountCubit(
        FakeAccountRepository(
          signInError: const AccountException(AccountFailure.failed),
        ),
      );
      expect(await failed.signIn(), isNull);
      expect(failed.state.failure, AccountFailure.failed);
    });

    test('설정이 없는 빌드는 지원 여부만 알린다', () async {
      final cubit = _accountCubit(
        FakeAccountRepository(support: AccountSupport.notConfigured),
      );
      await cubit.load();
      expect(cubit.state.support, AccountSupport.notConfigured);
    });
  });

  group('내 재생목록 가져오기', () {
    test('로그인한 계정의 재생목록을 목록으로 보여 준다', () async {
      const mine = PlaylistHit(id: 'PL1', title: '내 목록', url: 'u');
      final cubit = _importCubit(
        FakeAccountRepository(
          account: const GoogleAccount(id: 'u', email: 'a@b.c'),
          playlists: [mine],
        ),
      );
      await cubit.loadMine();
      expect(cubit.state.status, PlaylistImportStatus.results);
      expect(cubit.state.mine, isTrue);
      expect(cubit.state.results, [mine]);
    });

    test('로그인이 풀렸으면 로그인이 필요하다고 알린다', () async {
      final cubit = _importCubit(FakeAccountRepository());
      await cubit.loadMine();
      expect(cubit.state.status, PlaylistImportStatus.failed);
      expect(cubit.state.accountFailure, AccountFailure.unauthorized);
    });

    test('유튜브 채널이 없는 계정이면 채널이 없다고 알린다', () async {
      final cubit = _importCubit(
        FakeAccountRepository(
          account: const GoogleAccount(id: 'u', email: 'a@b.c'),
          playlistsError: const AccountException(AccountFailure.noChannel),
        ),
      );
      await cubit.loadMine();
      expect(cubit.state.status, PlaylistImportStatus.failed);
      expect(cubit.state.accountFailure, AccountFailure.noChannel);
    });
  });

  group('구독 채널의 재생목록 가져오기', () {
    const signedIn = GoogleAccount(id: 'u', email: 'a@b.c');

    test('채널의 업로드 전체를 맨 위에 두고 그 채널의 재생목록을 이어 보여 준다', () async {
      const list = PlaylistHit(id: 'PL1', title: '모음', url: 'u');
      final cubit = _importCubit(
        FakeAccountRepository(
          account: signedIn,
          channelPlaylistsById: {
            'UCabc': [list],
          },
        ),
      );
      await cubit.loadChannel('UCabc', '채널', '업로드');
      expect(cubit.state.status, PlaylistImportStatus.results);
      expect(cubit.state.channel, '채널');
      expect(cubit.state.results.first.id, 'UUabc');
      expect(
        cubit.state.results.first.url,
        'https://www.youtube.com/playlist?list=UUabc',
      );
      expect(cubit.state.results.last, list);
    });

    test('로그인이 풀렸으면 로그인이 필요하다고 알린다', () async {
      final cubit = _importCubit(FakeAccountRepository());
      await cubit.loadChannel('UCabc', '채널', '업로드');
      expect(cubit.state.status, PlaylistImportStatus.failed);
      expect(cubit.state.accountFailure, AccountFailure.unauthorized);
      expect(cubit.state.fromAccount, isTrue);
    });
  });
}

import 'dart:math';
import 'dart:ui' show Color, Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/library/domain/entities/library_sort.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/notifications/domain/entities/notification_settings.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/download_notifier.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/media_session.dart';
import 'package:music_download_play_app/features/notifications/presentation/bloc/notification_sync_cubit.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/security/domain/usecases/app_lock_usecases.dart';
import 'package:music_download_play_app/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:music_download_play_app/features/theme/domain/usecases/theme_usecases.dart';
import 'package:music_download_play_app/features/theme/presentation/bloc/theme_cubit.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

Track _t(String id, {String artist = '', int day = 1}) => Track(
  id: id,
  title: id,
  artist: artist,
  album: '',
  genre: '',
  duration: const Duration(minutes: 3),
  addedAt: DateTime(2026, 1, day),
);

void main() {
  test('보관함 셔플은 첫 곡이 아니라 무작위 곡에서 시작한다', () {
    final tracks = TestData.tracks.take(3).toList();
    final c = NowPlayingCubit(random: _FixedRandom(2));
    addTearDown(c.close);
    c.playShuffled(tracks);
    expect(c.state.shuffle, isTrue);
    expect(c.state.track, tracks[2]);
    expect(c.state.queue.toSet(), tracks.toSet());
  });

  test('묶음 정렬: 이름순 · 곡 수순 · 최근 추가순', () {
    final groups = {
      'B': [_t('1', day: 1), _t('2', day: 2)],
      'A': [_t('3', day: 1)],
      'C': [_t('4', day: 9)],
    };
    expect(sortGroups(groups, LibrarySort.name).keys, ['A', 'B', 'C']);
    expect(sortGroups(groups, LibrarySort.count).keys, ['B', 'A', 'C']);
    expect(sortGroups(groups, LibrarySort.added).keys, ['C', 'B', 'A']);
  });

  group('앱 잠금: 백그라운드에서 돌아오면 다시 잠근다', () {
    late DateTime clock;
    late AppLockCubit c;

    setUp(() async {
      clock = DateTime(2026);
      final repo = MemoryAppLockRepository(pin: '1234');
      final bio = FakeBiometricAuthenticator();
      c = AppLockCubit(
        load: LoadAppLock(repo),
        enable: EnableAppLock(repo),
        disable: DisableAppLock(repo),
        turnOff: TurnOffAppLock(repo),
        verify: VerifyPin(repo),
        setBiometric: SetBiometric(repo),
        isBiometricAvailable: IsBiometricAvailable(bio),
        authenticateBiometric: AuthenticateBiometric(bio),
        now: () => clock,
      );
      await c.load();
      await c.unlock('1234');
    });
    tearDown(() => c.close());

    test('잠깐(10초 미만) 나갔다 오면 그대로', () {
      c.appLeft();
      clock = clock.add(const Duration(seconds: 3));
      c.appReturned();
      expect(c.state.locked, isFalse);
    });

    test('오래 나갔다 오면(알림으로 돌아오는 경우 포함) 잠금 화면이 먼저 뜬다', () {
      c.appLeft();
      clock = clock.add(AppLockCubit.relockAfter);
      c.appReturned();
      expect(c.state.locked, isTrue);
    });
  });

  test('곡 분위기 따라가기는 저장되고, 끄면 고른 프리셋으로 돌아간다', () async {
    final repo = MemoryThemeSettingsRepository();
    final c = ThemeCubit(
      loadSettings: LoadThemeSettings(repo),
      savePreset: SaveThemePreset(repo),
      saveMode: SaveThemeMode(repo),
      saveFollowMood: SaveFollowMood(repo),
    );
    addTearDown(c.close);
    await c.setFollowMood(true);
    expect(c.state.followMood, isTrue);
    expect(repo.settings.followMood, isTrue);
    await c.apply(
      const MoodColorThemeSource(trackId: 't', color: Color(0xFF3366CC)),
    );
    expect(c.state.sourceId, startsWith('mood-color:t'));
    await c.setFollowMood(false);
    expect(repo.settings.followMood, isFalse);
    expect(c.state.sourceId, c.state.preset.id);
  });

  group('알림', () {
    late FakeDownloadNotifier notifier;
    late FakeMediaSession session;
    late NotificationSyncCubit cubit;
    final l10n = lookupAppLocalizations(const Locale('ko'));

    setUp(() async {
      await setUpTestDependencies();
      notifier = sl<DownloadNotifier>() as FakeDownloadNotifier;
      session = sl<MediaSession>() as FakeMediaSession;
      cubit = sl<NotificationSyncCubit>();
    });

    test('곡 정보 숨김 중에는 대기열 속 순번이 알림에 보여 곡 이동을 알 수 있다', () async {
      final track = TestData.tracks.first;
      Future<void> at(int i) => cubit.syncPlayback(
        track: track,
        isPlaying: true,
        position: Duration.zero,
        hasPrevious: true,
        hasNext: true,
        artUri: null,
        queueIndex: i,
        queueLength: 5,
        settings: const NotificationSettings(hideSongInfo: true),
        l10n: l10n,
        now: DateTime(2026),
      );
      await at(0);
      await at(1);
      expect(session.updates, hasLength(2));
      expect(session.updates.first!.artist, '곡 정보 숨김 · 1/5번째 곡');
      expect(session.updates.last!.artist, '곡 정보 숨김 · 2/5번째 곡');
    });

    test('받는 중 알림은 지금 받는 곡의 id를 실어 누르면 그 곡 상세로 간다', () async {
      await cubit.syncDownloads(
        [
          const DownloadItem(
            id: 'a',
            title: '곡a',
            artist: '가수',
            status: DownloadStatus.downloading,
            progress: .3,
          ),
        ],
        const NotificationSettings(),
        l10n,
      );
      expect(notifier.shown.last['openId'], 'a');
    });

    test('알림 누름은 열려 있을 때는 스트림으로, 새로 켜졌을 때는 한 번 가져간다', () async {
      expectLater(cubit.downloadOpens, emits('x'));
      notifier.pressBody('x');
      notifier.launchedWith = 'y';
      expect(await cubit.takeDownloadOpen(), 'y');
      expect(await cubit.takeDownloadOpen(), isNull);
    });
  });
}

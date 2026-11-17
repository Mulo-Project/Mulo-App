import 'dart:ui' show Locale;

import 'package:music_download_play_app/features/notifications/domain/repositories/download_notifier.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/media_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/notifications/domain/entities/media_session_info.dart';
import 'package:music_download_play_app/features/notifications/domain/entities/notification_settings.dart';
import 'package:music_download_play_app/features/notifications/presentation/bloc/notification_sync_cubit.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeDownloadNotifier notifier;
  late FakeMediaSession session;
  late NotificationSyncCubit cubit;
  final l10n = lookupAppLocalizations(const Locale('ko'));
  const on = NotificationSettings();

  setUp(() async {
    await setUpTestDependencies();
    notifier = sl<DownloadNotifier>() as FakeDownloadNotifier;
    session = sl<MediaSession>() as FakeMediaSession;
    cubit = sl<NotificationSyncCubit>();
  });

  test('받기 알림 글과 설정은 네이티브에 한 번 넘기고, 바뀔 때만 다시 넘긴다', () async {
    await cubit.syncDownloadConfig(on, l10n);
    final first = notifier.downloadConfig!;
    expect(first['progress'], contains('{p}'));
    expect(first['progressNext'], allOf(contains('{p}'), contains('{t}')));
    expect(first['overall'], allOf(contains('{d}'), contains('{n}')));
    expect(first['saveLocation'], contains('{f}'));
    expect(first['retry'], l10n.notifDownloadRetry);
    expect(first['hide'], isFalse);

    notifier.downloadConfig = null;
    await cubit.syncDownloadConfig(on, l10n);
    expect(notifier.downloadConfig, isNull, reason: '같은 내용은 다시 넘기지 않는다');

    await cubit.syncDownloadConfig(
      const NotificationSettings(hideSongInfo: true),
      l10n,
    );
    expect(notifier.downloadConfig!['hide'], isTrue);
  });

  test('받기 결과 알림과 백그라운드 받기 설정을 그대로 넘긴다', () async {
    await cubit.syncDownloadConfig(
      const NotificationSettings(
        downloadResult: false,
        backgroundDownload: false,
      ),
      l10n,
    );
    expect(notifier.downloadConfig!['results'], isFalse);
    expect(notifier.downloadConfig!['keepAlive'], isFalse);
  });

  test('받는 곡을 미리 듣는 중이면 네이티브에 알리고, 같은 값은 다시 보내지 않는다', () async {
    await cubit.syncDownloadPreviewing('1');
    expect(notifier.previewing, '1');
    notifier.previewing = 'x';
    await cubit.syncDownloadPreviewing('1');
    expect(notifier.previewing, 'x', reason: '같은 곡은 다시 알리지 않는다');
    await cubit.syncDownloadPreviewing(null);
    expect(notifier.previewing, isNull);
  });

  test('재생 알림은 위치가 흘러가는 동안 다시 보내지 않고 이동하면 보낸다', () async {
    await play(on);
    await play(on, at: const Duration(milliseconds: 500));
    expect(session.updates, hasLength(1));
    await play(on, at: const Duration(minutes: 1));
    expect(session.updates, hasLength(2));
    await play(on, at: const Duration(minutes: 1), playing: false);
    expect(session.updates.last!.playing, isFalse);
  });

  test('좋아요 상태가 바뀌면 알림을 다시 보낸다', () async {
    Future<void> sync(bool favorite) => cubit.syncPlayback(
      track: track,
      isPlaying: true,
      position: Duration.zero,
      hasPrevious: true,
      hasNext: true,
      artUri: null,
      favorite: favorite,
      settings: on,
      l10n: l10n,
      now: DateTime(2026),
    );
    await sync(false);
    await sync(false);
    expect(session.updates, hasLength(1));
    await sync(true);
    expect(session.updates, hasLength(2));
    expect(session.updates.last!.favorite, isTrue);
  });

  test('셔플을 켜고 끄면 알림을 다시 보낸다 (알림의 셔플 버튼 모양)', () async {
    Future<void> sync(bool shuffle) => cubit.syncPlayback(
      track: track,
      isPlaying: true,
      position: Duration.zero,
      hasPrevious: true,
      hasNext: true,
      artUri: null,
      shuffle: shuffle,
      settings: on,
      l10n: l10n,
      now: DateTime(2026),
    );
    await sync(false);
    await sync(false);
    expect(session.updates, hasLength(1));
    await sync(true);
    expect(session.updates, hasLength(2));
    expect(session.updates.last!.shuffle, isTrue);
  });

  test('수면 타이머가 켜져 있으면 끝나는 시각이 부제목에 붙고, 꺼지면 사라진다', () async {
    Future<void> sync(DateTime? end) => cubit.syncPlayback(
      track: track,
      isPlaying: true,
      position: Duration.zero,
      hasPrevious: true,
      hasNext: true,
      artUri: null,
      sleepEndsAt: end,
      settings: on,
      l10n: l10n,
      now: DateTime(2026),
    );
    await sync(DateTime(2026, 1, 1, 3, 5));
    expect(session.updates.last!.artist, '가수 · 03:05에 수면 타이머');
    await sync(null);
    expect(session.updates.last!.artist, '가수');
  });

  test('곡 정보 숨기기를 켜면 제목 · 아티스트 · 커버를 보내지 않는다', () async {
    await play(on.copyWith(hideSongInfo: true));
    final info = session.updates.single!;
    expect(info.title, '음악 재생 중');
    expect(info.artist, '곡 정보 숨김');
    expect(info.artUri, isNull);
  });

  group('미리 듣기', () {
    Future<void> sync({
      PreviewNotice? preview,
      Track? current,
      NotificationSettings settings = on,
    }) => cubit.syncPlayback(
      track: current,
      preview: preview,
      isPlaying: false,
      position: Duration.zero,
      hasPrevious: true,
      hasNext: true,
      artUri: null,
      settings: settings,
      l10n: l10n,
      now: DateTime(2026),
    );

    const notice = PreviewNotice(
      title: '미리 곡',
      uploader: '채널',
      position: Duration(seconds: 5),
      duration: Duration(minutes: 2),
    );

    test('재생 알림이 미리 듣기 곡으로 바뀌고 끝나면 앞의 곡으로 돌아간다', () async {
      await sync(current: track);
      await sync(current: track, preview: notice);
      final shown = session.updates.last!;
      expect(shown.preview, isTrue);
      expect(shown.title, '미리 곡');
      expect(shown.artist, '채널 · 미리 듣기');
      expect(shown.hasNext, isFalse);
      await sync(current: track);
      expect(session.updates.last!.title, '노래');
      expect(session.updates.last!.preview, isFalse);
    });

    test('일시정지하면 알림도 멈춘 모양으로 바뀐다', () async {
      await sync(current: track, preview: notice);
      expect(session.updates.last!.playing, isTrue);
      await sync(
        current: track,
        preview: const PreviewNotice(
          title: '미리 곡',
          uploader: '채널',
          position: Duration(seconds: 5),
          duration: Duration(minutes: 2),
          paused: true,
        ),
      );
      expect(session.updates.last!.preview, isTrue);
      expect(session.updates.last!.playing, isFalse);
    });

    test('재생 중인 곡이 없어도 보이고, 끝나면 알림을 치운다', () async {
      await sync(preview: notice);
      expect(session.updates.last!.preview, isTrue);
      await sync();
      expect(session.updates.last, isNull);
    });

    test('곡 정보 숨기기를 켜면 미리 듣는 곡 정보도 숨긴다', () async {
      await sync(preview: notice, settings: on.copyWith(hideSongInfo: true));
      final info = session.updates.last!;
      expect(info.title, '음악 재생 중');
      expect(info.artist, '곡 정보 숨김 · 미리 듣기');
      expect(info.artUri, isNull);
    });

    test('재생 알림을 끄면 미리 듣기도 알림에 안 띄운다', () async {
      await sync(preview: notice, settings: on.copyWith(playback: false));
      expect(session.updates, isEmpty);
    });
  });

  test('기본 커버 색은 숨기기를 끄면 보내고 켜면 보내지 않는다', () async {
    Future<void> sync(NotificationSettings s) => cubit.syncPlayback(
      track: track,
      isPlaying: true,
      position: Duration.zero,
      hasPrevious: true,
      hasNext: true,
      artUri: null,
      coverColors: const [1, 2, 3],
      settings: s,
      l10n: l10n,
      now: DateTime(2026),
    );
    await sync(on);
    expect(session.updates.last!.coverColors, [1, 2, 3]);
    await sync(on.copyWith(hideSongInfo: true));
    expect(session.updates.last!.coverColors, isEmpty);
  });

  test('재생 알림을 끄면 알림을 치운다', () async {
    await play(on);
    await play(on.copyWith(playback: false));
    expect(session.updates.last, isNull);
  });
}

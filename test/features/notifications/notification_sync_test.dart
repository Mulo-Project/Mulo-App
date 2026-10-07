import 'dart:ui' show Locale;

import 'package:music_download_play_app/features/notifications/domain/repositories/download_notifier.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/media_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/notifications/domain/entities/media_session_info.dart';
import 'package:music_download_play_app/features/notifications/domain/entities/notification_settings.dart';
import 'package:music_download_play_app/features/notifications/presentation/bloc/notification_sync_cubit.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

DownloadItem item(String id, DownloadStatus s, [double p = 0]) =>
    DownloadItem(id: id, title: '곡$id', artist: '가수', status: s, progress: p);

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

  test('받는 중 알림은 퍼센트가 바뀔 때만 갱신하고 끝나면 치운다', () async {
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading, .4)],
      on,
      l10n,
    );
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading, .4)],
      on,
      l10n,
    );
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading, .5)],
      on,
      l10n,
    );
    await cubit.syncDownloads([item('1', DownloadStatus.done, 1)], on, l10n);
    expect(notifier.calls, [
      'progress:곡1:40',
      'progress:곡1:50',
      'done:1',
      'clear',
    ]);
  });

  test('끝남 · 실패는 곡마다 한 번만 알리고, 결과 알림을 끄면 알리지 않는다', () async {
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading)],
      on,
      l10n,
    );
    await cubit.syncDownloads([item('1', DownloadStatus.failed)], on, l10n);
    await cubit.syncDownloads([item('1', DownloadStatus.failed)], on, l10n);
    expect(notifier.calls.where((c) => c == 'failed:1'), hasLength(1));
    notifier.calls.clear();
    await cubit.syncDownloads(
      [item('2', DownloadStatus.done)],
      on.copyWith(downloadResult: false),
      l10n,
    );
    expect(notifier.calls.where((c) => c.startsWith('done')), isEmpty);
  });

  test('진행 알림을 끄면 알림을 치운다', () async {
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading, .1)],
      on,
      l10n,
    );
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading, .2)],
      on.copyWith(downloadProgress: false),
      l10n,
    );
    expect(notifier.calls.last, 'clear');
  });

  final track = Track(
    id: 't',
    title: '노래',
    artist: '가수',
    album: '',
    duration: const Duration(minutes: 3),
    addedAt: DateTime(2026),
  );

  Future<void> play(
    NotificationSettings s, {
    Duration? at,
    bool playing = true,
  }) => cubit.syncPlayback(
    track: track,
    isPlaying: playing,
    position: at ?? Duration.zero,
    hasPrevious: true,
    hasNext: true,
    artUri: 'https://example.com/c.jpg',
    settings: s,
    l10n: l10n,
    now: DateTime(2026),
  );

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

  test('곡 정보 숨기기를 켜면 제목 · 아티스트 · 커버를 보내지 않는다', () async {
    await play(on.copyWith(hideSongInfo: true));
    final info = session.updates.single!;
    expect(info.title, '음악 재생 중');
    expect(info.artist, isEmpty);
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
      expect(shown.artist, '미리 듣기 · 채널');
      expect(shown.hasNext, isFalse);
      await sync(current: track);
      expect(session.updates.last!.title, '노래');
      expect(session.updates.last!.preview, isFalse);
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
      expect(info.artist, '미리 듣기');
      expect(info.artUri, isNull);
    });

    test('재생 알림을 끄면 미리 듣기도 알림에 안 띄운다', () async {
      await sync(preview: notice, settings: on.copyWith(playback: false));
      expect(session.updates, isEmpty);
    });
  });

  test('재생 알림을 끄면 알림을 치운다', () async {
    await play(on);
    await play(on.copyWith(playback: false));
    expect(session.updates.last, isNull);
  });
}

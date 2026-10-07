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
      on.copyWith(downloadProgress: false, backgroundDownload: false),
      l10n,
    );
    expect(notifier.calls.last, 'clear');
  });

  test('진행 알림에 지금 곡 · 다음 곡 · 전체 진행률과 미리듣기 버튼을 담는다', () async {
    // 끝난 곡도 이번 묶음에 세려면 받는 동안 한 번은 보여야 한다.
    await cubit.syncDownloads(
      [
        item('1', DownloadStatus.downloading, .9),
        item('2', DownloadStatus.queued),
        item('3', DownloadStatus.queued),
        item('4', DownloadStatus.queued),
      ],
      on,
      l10n,
    );
    notifier.shown.clear();
    notifier.calls.clear();
    await cubit.syncDownloads(
      [
        item('1', DownloadStatus.done, 1),
        item('2', DownloadStatus.downloading, .5),
        item('3', DownloadStatus.queued),
        item('4', DownloadStatus.queued),
      ],
      on,
      l10n,
    );
    final shown = notifier.shown.single;
    expect(shown['title'], '곡2');
    expect(shown['body'], contains('다음 곡: 곡3'));
    expect(shown['body'], startsWith('가수 · '));
    expect(shown['cancel'], '취소');
    expect(shown['subText'], '전체 1/4곡 · 38%');
    expect(shown['preview'], '미리듣기');
    expect(notifier.calls.last, 'progress:곡2:38');
  });

  test('곡 정보 숨기기를 켜면 제목 · 다음 곡 · 미리듣기를 알림에 담지 않는다', () async {
    await cubit.syncDownloads(
      [
        item('1', DownloadStatus.downloading, .5),
        item('2', DownloadStatus.queued),
      ],
      on.copyWith(hideSongInfo: true),
      l10n,
    );
    final shown = notifier.shown.single;
    expect(shown['title'], l10n.notifDownloadHiddenTitle);
    expect(shown['body'], isNot(contains('곡2')));
    expect(shown['preview'], isNull);
  });

  test('백그라운드 받기 설정이 앞에 붙들기를 정하고, 진행 알림이 꺼져도 붙든다', () async {
    final downloading = [item('1', DownloadStatus.downloading, .2)];
    await cubit.syncDownloads(downloading, on, l10n);
    expect(notifier.shown.last['foreground'], isTrue);
    await cubit.syncDownloads(
      downloading,
      on.copyWith(backgroundDownload: false),
      l10n,
    );
    expect(notifier.shown.last['foreground'], isFalse);
    // 진행 알림은 껐지만 백그라운드 받기는 켠 경우: 서비스에 필요한 알림만 남는다.
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading, .3)],
      on.copyWith(downloadProgress: false),
      l10n,
    );
    expect(notifier.shown.last['foreground'], isTrue);
    // 둘 다 끄면 알림도 서비스도 없다.
    await cubit.syncDownloads(
      [item('1', DownloadStatus.downloading, .4)],
      on.copyWith(downloadProgress: false, backgroundDownload: false),
      l10n,
    );
    expect(notifier.calls.last, 'clear');
  });

  test('받기를 시작하자마자(아직 대기 상태여도) 진행 알림을 바로 띄운다', () async {
    await cubit.syncDownloads(
      [item('1', DownloadStatus.queued), item('2', DownloadStatus.queued)],
      on,
      l10n,
    );
    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single['title'], '곡1');
    expect(notifier.shown.single['body'], contains('다음 곡: 곡2'));
  });

  test('지금 곡을 미리 듣는 중이면 미리듣기 버튼이 일시정지 · 중지로 바뀐다', () async {
    final downloading = [item('1', DownloadStatus.downloading, .3)];
    await cubit.syncDownloads(downloading, on, l10n);
    expect(notifier.shown.last['preview'], '미리듣기');
    expect(notifier.shown.last['pause'], isNull);
    await cubit.syncDownloads(downloading, on, l10n, previewingId: '1');
    expect(notifier.shown.last['preview'], isNull);
    expect(notifier.shown.last['pause'], '일시정지');
    expect(notifier.shown.last['stop'], '중지');
    await cubit.syncDownloads(
      downloading,
      on,
      l10n,
      previewingId: '1',
      previewPaused: true,
    );
    expect(notifier.shown.last['pause'], '이어 듣기');
    // 다른 곡을 미리 듣는 중이면 이 곡의 버튼은 그대로.
    await cubit.syncDownloads(downloading, on, l10n, previewingId: 'x');
    expect(notifier.shown.last['preview'], '미리듣기');
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

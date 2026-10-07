import 'dart:convert';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/account/domain/usecases/account_usecases.dart';
import 'package:music_download_play_app/features/downloads/domain/usecases/download_usecases.dart';
import 'package:music_download_play_app/features/playlists/domain/usecases/playlist_usecases.dart';
import 'package:music_download_play_app/features/playlists/presentation/bloc/playlist_import_cubit.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';

import '../../helpers/fakes.dart';

MediaHit _hit(String id, {String? thumb}) => MediaHit(
  id: id,
  title: 'Title $id',
  url: 'https://example.com/$id',
  uploader: 'Artist',
  thumbnailUrl: thumb,
);

const _url = 'https://example.com/playlist?list=PL1';

({
  PlaylistImportCubit cubit,
  MemoryDownloadQueue queue,
  MemoryPlaylistRepository lists,
})
_setUp(MediaInfo info) {
  final queue = MemoryDownloadQueue();
  final lists = MemoryPlaylistRepository();
  final engine = FakeDownloaderEngine(infoByUrl: {_url: info});
  return (
    cubit: PlaylistImportCubit(
      FetchMediaInfo(engine),
      SearchPlaylists(engine),
      FetchMyPlaylists(FakeAccountRepository()),
      EnqueueDownload(queue),
      CreatePlaylist(lists),
    ),
    queue: queue,
    lists: lists,
  );
}

void main() {
  _searchTests();
  test('주소를 읽으면 곡을 모두 고른 채로 보여 주고, 대표 이미지는 첫 곡으로 대신한다', () async {
    final s = _setUp(
      PlaylistInfo(
        title: '내 목록',
        entries: [
          _hit('a', thumb: 't1'),
          _hit('b'),
        ],
      ),
    );
    await s.cubit.load(_url);
    expect(s.cubit.state.status, PlaylistImportStatus.loaded);
    expect(s.cubit.state.selected, {'a', 'b'});
    expect(s.cubit.state.thumbnailUrl, 't1');
    s.cubit.toggleAll();
    expect(s.cubit.state.selected, isEmpty);
    s.cubit.toggleAll();
    expect(s.cubit.state.allSelected, isTrue);
  });

  test('곡 하나의 주소면 재생목록이 아니라고 알린다', () async {
    final s = _setUp(VideoInfo(_hit('a')));
    await s.cubit.load(_url);
    expect(s.cubit.state.status, PlaylistImportStatus.failed);
    expect(s.cubit.state.notPlaylist, isTrue);
  });

  test('고른 곡만 새 재생목록 이름으로 받기 대기열에 넣는다', () async {
    final s = _setUp(
      PlaylistInfo(
        title: '내 목록',
        thumbnailUrl: 'cover',
        entries: [_hit('a'), _hit('b'), _hit('c')],
      ),
    );
    await s.cubit.load(_url);
    s.cubit.toggle('b');
    final result = await s.cubit.start();

    expect(result?.queued, 2);
    expect(result?.thumbnailUrl, 'cover');
    expect(s.queue.requests.map((r) => r.title), ['Title a', 'Title c']);
    expect(
      s.queue.requests.every(
        (r) => setEquals(r.playlistIds, {result!.playlistId}),
      ),
      isTrue,
    );
    final made = (await s.lists.watchPlaylists().first).last;
    expect(made.name, '내 목록');
  });

  test('고른 곡이 없으면 아무것도 만들지 않는다', () async {
    final s = _setUp(PlaylistInfo(title: '내 목록', entries: [_hit('a')]));
    await s.cubit.load(_url);
    s.cubit.toggleAll();
    expect(await s.cubit.start(), isNull);
    expect(s.queue.requests, isEmpty);
  });
}

void _searchTests() {
  const found = PlaylistHit(
    id: 'PL1',
    title: '운동할 때',
    url: _url,
    channel: '채널',
    trackCount: 30,
  );

  test('키워드를 넣으면 재생목록을 찾아 보여 주고, 하나를 열면 곡 목록을 읽는다', () async {
    final queue = MemoryDownloadQueue();
    final lists = MemoryPlaylistRepository();
    final engine = FakeDownloaderEngine(
      infoByUrl: {
        _url: PlaylistInfo(title: '운동할 때', entries: [_hit('a')]),
      },
      playlistPage: const PlaylistSearchPage(items: [found], hasNext: false),
    );
    final cubit = PlaylistImportCubit(
      FetchMediaInfo(engine),
      SearchPlaylists(engine),
      FetchMyPlaylists(FakeAccountRepository()),
      EnqueueDownload(queue),
      CreatePlaylist(lists),
    );

    await cubit.submit('운동');
    expect(engine.playlistSearches, ['운동']);
    expect(cubit.state.status, PlaylistImportStatus.results);
    expect(cubit.state.results, [found]);

    await cubit.open(found);
    expect(cubit.state.status, PlaylistImportStatus.loaded);
    expect(cubit.state.results, [found]);

    cubit.backToResults();
    expect(cubit.state.status, PlaylistImportStatus.results);
  });

  test('주소를 넣으면 검색하지 않고 바로 곡 목록을 읽는다', () async {
    final engine = FakeDownloaderEngine(
      infoByUrl: {
        _url: PlaylistInfo(title: 't', entries: [_hit('a')]),
      },
    );
    final cubit = PlaylistImportCubit(
      FetchMediaInfo(engine),
      SearchPlaylists(engine),
      FetchMyPlaylists(FakeAccountRepository()),
      EnqueueDownload(MemoryDownloadQueue()),
      CreatePlaylist(MemoryPlaylistRepository()),
    );
    await cubit.submit(_url);
    expect(engine.playlistSearches, isEmpty);
    expect(cubit.state.status, PlaylistImportStatus.loaded);
  });

  test('LocalEngine: 재생목록 검색 결과에서 이름 · 채널 · 곡 수를 읽는다', () async {
    List<String>? args;
    final engine = LocalEngine(
      run: (_, a) async {
        args = a;
        return (
          exitCode: 0,
          stdout:
              '${jsonEncode({
                'id': 'PL1',
                'title': 'T',
                'url': 'https://www.youtube.com/playlist?list=PL1',
                'uploader': 'U',
                'playlist_count': 12,
                'thumbnails': [
                  {'url': 'th'},
                ],
              })}\n'
              '${jsonEncode({'id': 'vid', 'title': 'video', 'url': 'https://www.youtube.com/watch?v=vid'})}\n',
          stderr: '',
        );
      },
    );
    final page = await engine.searchPlaylists('q');
    expect(args!.last, contains('sp=EgIQAw%253D%253D'));
    expect(page.items, hasLength(1));
    expect(page.items.single.channel, 'U');
    expect(page.items.single.trackCount, 12);
    expect(page.items.single.thumbnailUrl, 'th');
  });
}

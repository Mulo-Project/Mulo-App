import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/usecases/cover_usecases.dart';
import 'package:music_download_play_app/features/covers/presentation/bloc/cover_cubit.dart';

import '../../helpers/fakes.dart';

CoverCubit _cubit(MemoryCoverRepository repo, FakeImageSource source) =>
    CoverCubit(
      load: LoadCovers(repo),
      clear: ClearCover(repo),
      pickFile: PickImageFile(source),
      save: SaveCover(repo),
      saveWeb: SaveWebCover(repo),
      setTransform: SetCoverTransform(repo),
    );

void main() {
  const moved = CoverTransform(scale: 2, dx: .1, dy: -.2);

  test('pickFile은 저장 없이 경로만 돌려주고, setFromFile로 키에 저장한다', () async {
    final repo = MemoryCoverRepository();
    final c = _cubit(repo, FakeImageSource('/tmp/b.png'));
    addTearDown(c.close);
    expect(await c.pickFile(), '/tmp/b.png');
    expect(repo.saved, isEmpty);
    await c.setFromFile(CoverKey.playlist('pl1'), '/tmp/b.png', moved);
    expect(
      c.state[CoverKey.playlist('pl1')],
      const CoverArt.file('/tmp/b.png', transform: moved),
    );
    expect(repo.saved, c.state);
  });

  test('웹 이미지는 주소와 위치만 저장한다', () async {
    final repo = MemoryCoverRepository();
    final c = _cubit(repo, FakeImageSource());
    addTearDown(c.close);
    await c.setArt(
      CoverKey.track('t01'),
      const CoverArt.web('https://x.test/a.jpg', transform: moved),
    );
    final art = c.state[CoverKey.track('t01')]!;
    expect(art.isWeb, isTrue);
    expect(art.path, isNull);
    expect(art.url, 'https://x.test/a.jpg');
    expect(art.transform, moved);
    expect(repo.saved[CoverKey.track('t01')], art);
  });

  test('setTransform은 이미지는 두고 위치 · 확대만 바꾼다', () async {
    final repo = MemoryCoverRepository();
    final c = _cubit(repo, FakeImageSource());
    addTearDown(c.close);
    final key = CoverKey.track('t01');
    await c.setFromUrl(key, 'https://x.test/a.jpg');
    await c.setTransform(key, moved);
    expect(c.state[key]!.url, 'https://x.test/a.jpg');
    expect(c.state[key]!.transform, moved);
    expect(repo.saved[key]!.transform, moved);
    // 커버가 없는 키는 건드리지 않는다.
    await c.setTransform(CoverKey.track('none'), moved);
    expect(c.state.keys, [key]);
  });

  test('clear는 상태와 저장소에서 지운다', () async {
    final repo = MemoryCoverRepository();
    final c = _cubit(repo, FakeImageSource());
    addTearDown(c.close);
    await c.setFromFile(CoverKey.track('t01'), '/tmp/a.png');
    await c.setFromFile(CoverKey.track('t02'), '/tmp/a.png');
    await c.clear(CoverKey.track('t01'));
    expect(c.state.keys, [CoverKey.track('t02')]);
    expect(repo.saved.keys, [CoverKey.track('t02')]);
  });

  test('load는 저장된 커버를 불러온다', () async {
    final repo = MemoryCoverRepository()
      ..saved['playlist:Focus'] = const CoverArt.file('/f.png');
    final c = _cubit(repo, FakeImageSource());
    addTearDown(c.close);
    await c.load();
    expect(c.state, {'playlist:Focus': const CoverArt.file('/f.png')});
  });
}

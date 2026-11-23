import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/saved_videos_cubit.dart';

import '../../helpers/fakes.dart';

const _hit = MediaHit(id: 's', title: 'SC', url: 'https://soundcloud.com/a/b');

void main() {
  test('저장을 누르면 주소를 읽는 동안에도 목록에 받는 중으로 들어간다', () async {
    final gate = Completer<void>();
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(streamGate: gate.future),
    );
    final cubit = sl<SavedVideosCubit>();
    // 켤 때 목록을 읽는 일이 끝난 뒤에 누른 것으로 한다.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final adding = cubit.add(_hit);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.contains('s'), isTrue);
    expect(cubit.state.single.ready, isFalse);
    gate.complete();
    await adding;
    await cubit.close();
  });

  test('주소를 못 읽으면 목록에서 도로 빠진다', () async {
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(streamFailure: EngineFailure.failed),
    );
    final cubit = sl<SavedVideosCubit>();
    expect(await cubit.add(_hit), isFalse);
    expect(cubit.contains('s'), isFalse);
    await cubit.close();
  });

  test('상세 정보가 빈 곡은 저장하기 전에 읽어서 함께 저장한다', () async {
    final full = MediaHit(
      id: 's',
      title: 'SC',
      url: 'https://soundcloud.com/a/b',
      viewCount: 10,
      uploadedAt: DateTime(2026, 1, 2),
      channelUrl: 'https://soundcloud.com/a',
      description: '설명',
    );
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(info: VideoInfo(full)),
    );
    final cubit = sl<SavedVideosCubit>();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(await cubit.add(_hit), isTrue);
    final saved = cubit.state.single.hit;
    expect(saved.viewCount, 10);
    expect(saved.description, '설명');
    await cubit.close();
  });
}

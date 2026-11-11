import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/download_queue_store.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_language.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/audio_language_cubit.dart';
import 'package:music_download_play_app/features/search/presentation/widgets/audio_language_sheet.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

const _tracks = [
  AudioLanguage(id: 'en', name: 'English', isDefault: true),
  AudioLanguage(id: 'ko', name: 'Korean'),
];

void main() {
  test('AudioLanguageCubit: 기본은 원본 음성이고 고른 언어가 현재가 된다', () async {
    final engine = FakeDownloaderEngine()..audioLanguages = _tracks;
    final cubit = AudioLanguageCubit(FetchAudioLanguages(engine));
    await cubit.load('https://x/v');
    expect(cubit.state.choosable, isTrue);
    expect(cubit.state.selected, isNull);
    expect(cubit.state.current?.id, 'en');
    cubit.select('ko');
    expect(cubit.state.current?.id, 'ko');
    cubit.select('zz'); // 없는 언어는 무시한다.
    expect(cubit.state.selected, 'ko');
  });

  test('AudioLanguageCubit: 시스템 언어와 맞는 트랙이 기본으로 골라진다', () async {
    final engine = FakeDownloaderEngine()..audioLanguages = _tracks;
    final cubit = AudioLanguageCubit(
      FetchAudioLanguages(engine),
      systemLocale: () => const Locale('ko', 'KR'),
    );
    await cubit.load('https://x/v');
    expect(cubit.state.selected, 'ko');
    // 사용자가 고른 언어가 우선한다.
    cubit.select('en');
    expect(cubit.state.selected, 'en');
  });

  test('AudioLanguageCubit: 목록을 읽는 중이면 기다린 뒤 기본 언어를 돌려준다', () async {
    final engine = FakeDownloaderEngine()..audioLanguages = _tracks;
    final cubit = AudioLanguageCubit(
      FetchAudioLanguages(engine),
      systemLocale: () => const Locale('ko'),
    );
    final loading = cubit.load('https://x/v'); // 기다리지 않고 바로 묻는다.
    expect(await cubit.selectedWhenReady(), 'ko');
    await loading;
  });

  test('defaultAudioLanguageFor: 목록 타일에서도 같은 시스템 언어 기본값을 준다', () async {
    final engine = FakeDownloaderEngine()..audioLanguages = _tracks;
    final fetch = FetchAudioLanguages(engine);
    expect(
      await defaultAudioLanguageFor(
        fetch,
        'https://x/v',
        locale: const Locale('ko'),
      ),
      'ko',
    );
    // 영상의 기본 음성이 이미 시스템 언어면 따로 고르지 않는다.
    expect(
      await defaultAudioLanguageFor(
        fetch,
        'https://x/v',
        locale: const Locale('en'),
      ),
      isNull,
    );
  });

  test('AudioLanguageCubit: 트랙이 하나뿐이면 고를 수 없고, 모르는 언어 선택은 버린다', () async {
    final engine = FakeDownloaderEngine()
      ..audioLanguages = const [AudioLanguage(id: 'en', name: 'English')];
    final cubit = AudioLanguageCubit(FetchAudioLanguages(engine));
    await cubit.load('https://x/v', selected: 'ko');
    expect(cubit.state.selected, isNull);
    expect(cubit.state.choosable, isFalse);
  });

  test('받기 요청의 오디오 언어는 대기열에 저장했다가 그대로 읽는다', () {
    const request = DownloadRequest(
      title: 't',
      url: 'https://x/v',
      audioLanguage: 'ko',
    );
    expect(decodeDownloadRequest(encodeDownloadRequest(request)), request);
    expect(
      encodeDownloadRequest(
        const DownloadRequest(title: 't', url: 'https://x/v'),
      ).containsKey('audioLanguage'),
      isFalse,
    );
  });

  testWidgets('오디오 언어 줄을 누르면 시트가 열리고, 고르면 바로 적용된다', (tester) async {
    final engine = FakeDownloaderEngine()..audioLanguages = _tracks;
    final cubit = AudioLanguageCubit(FetchAudioLanguages(engine));
    await cubit.load('https://x/v');
    final changed = <String>[];
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          theme: buildAppTheme(AppPalette.defaultDark),
          home: Scaffold(body: AudioLanguageRow(onChanged: changed.add)),
        ),
      ),
    );
    expect(find.text('영어'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('audio-language-row')));
    await tester.pumpAndSettle();
    expect(find.text('원본'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('audio-language-ko')));
    await tester.pumpAndSettle();
    expect(cubit.state.selected, 'ko');
    expect(changed, ['ko']);
  });
}

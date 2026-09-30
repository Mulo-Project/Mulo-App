# 클린 아키텍처 + BLoC 전환

- 날짜: 2026-10-01
- 분류: 앱 · 설정
- 상태: 완료 (PR 대기)
- 브랜치: `refactor/clean-architecture-bloc` (`fix/settings-theme-mode-dark-default` 위)
- 상세 기능: 공통 (구조)

## 한 일
- D-019: Riverpod → flutter_bloc + get_it, 기능별 domain / data / presentation.
- `core/usecase/usecase.dart`(UseCase · StreamUseCase · NoParams), `core/di/injector.dart`(`sl`, `configureDependencies`).
- 기능 전환:
  - theme: `ThemeSettings` · `AppThemeMode`(domain), `ThemeSettingsRepository` + shared_preferences 구현, 유스케이스 3개, `ThemeCubit`
  - library: 엔티티 `Track` · `ScanResult` · `ImportOutcome`, `LibraryRepository` · `DeviceMusicRepository`, 유스케이스 `WatchLibraryTracks` · `ImportDeviceMusic`, 데이터 소스(MediaStore · 폴더), `LibraryCubit` · `LibraryImportCubit`(결과는 BlocListener로 스낵바)
  - covers: `CoverKey`, `CoverRepository` · `CoverImageSource`, 유스케이스 3개, `CoverCubit`
  - player: `PlayerRepeatMode`(domain), `NowPlayingCubit`
- 화면은 `presentation/screens/`로, `context.watch/select/read`로 bloc 사용. 앱 전체 bloc은 MultiBlocProvider.
- 테스트: `setUpTestDependencies()`(get_it 초기화 + 가짜 리포지토리), 큐빗 테스트(theme · cover · import · player), 의존 규칙 검사 `architecture_test.dart`.

## 바꾼 설정
- `pubspec.yaml`: + `flutter_bloc`, `get_it`, `equatable`, dev `bloc_test` / − `flutter_riverpod`

## 확인
- `flutter analyze` 0, `flutter test` 전부 통과 (33개), 아키텍처 검사 통과.

## 남은 일
- 다음: 탭 재구성 · 하단 탭 단색 바 · 홈.

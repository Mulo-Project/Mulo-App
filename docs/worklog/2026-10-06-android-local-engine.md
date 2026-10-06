# Android 로컬 엔진 (youtubedl-android)

- 날짜: 2026-10-06
- 분류: 앱 · 설정
- 상태: 완료 (PR 대기, 기기 실행 확인 필요)
- 브랜치 · 커밋: `feature/download-android-local-engine` (`feature/download-ytdlp-search`에서 분기, #46에 의존)
- 상세 기능: 공통 작업 (엔진 연결 · Android full 빌드)

## 한 일
- Android flavor `lite` / `full`. `default-flavor: full`.
- full: youtubedl-android로 APK 안의 yt-dlp 실행. Kotlin `YtDlpChannel`(`music_app/ytdlp`: available · version · run · update), lite는 빈 구현.
- Dart `AndroidYtDlp`가 채널을 감싸고, `LocalEngine`이 같은 검색 · 정보 코드로 Android에서도 돈다. 엔진 선택은 Android에서도 로컬 우선.
- 설정 엔진 줄: Android full에서 yt-dlp 버전 표시와 "업데이트", lite에서는 숨김.

## 바꾼 설정
- `android/app/build.gradle.kts`: productFlavors(lite · full), `fullImplementation(youtubedl-android:library:0.18.1)`, `jniLibs.useLegacyPackaging = true`.
- `pubspec.yaml`: `flutter.default-flavor: full`. Manifest 변경 없음 (INTERNET은 이미 있음).
- 새 네이티브 기능이므로 Notion 기술 스택(Native) DB에 youtubedl-android 행 추가가 필요하다 (아직 못 함).
- 라이선스: full 빌드에 GPL-3.0 라이브러리가 들어간다 (명세의 라이선스 항목과 연결).

## 확인
- `flutter analyze` 0, `flutter test` 전체 통과 (`android_yt_dlp_test.dart` 3개 추가).
- `flutter build apk --debug --flavor full` · `--flavor lite` · 기본(`flutter build apk --debug`) 모두 성공. 디버그 APK 크기 full 약 160MB, lite 약 114MB (ABI 4종 포함).
- 빌드 중 `libpython.zip.so`에 llvm-strip 경고가 나오지만 압축 파일이라 생기는 알려진 경고이고 빌드는 성공한다.
- 기기에서 실제 검색 · 첫 실행은 이 환경에서 돌려 보지 못했다.

## 남은 일 · 질문
- 첫 실행 때 파이썬 풀기가 몇 초 걸려 첫 검색이 느릴 수 있다 (진행 표시 없음).
- ffmpeg(오디오 추출), 실제 받기 · 대기열 · 보관함 등록은 다음 작업.
- release 빌드는 R8 · 압축 설정에서 라이브러리가 깨지는지 따로 확인해야 한다.

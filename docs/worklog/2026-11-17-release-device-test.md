# release 빌드 실기기 전체 테스트 · 수정

- 날짜: 2026-11-17
- 분류: 앱 · 설정
- 상태: 진행 중
- 브랜치 · 커밋: `fix/release-device-test`
- 상세 기능: 공통 (release 빌드 점검)

## 한 일
- #176(받기 엔진 네이티브 이전 + release R8 keep)을 develop에 합친 뒤, release 빌드로 전체 기능을 시험한다.
- 시험 목록은 `release-device-test-checklist.md`(프로젝트 공유 폴더 notes) 14개 섹션. 실패한 항목과 로그가 오면 이 PR 하나에서만 고친다 (PR을 쪼개지 않는다).
- 로그나 오류로 원인이 확인된 것만 고친다. 수정마다 건드린 곳과 안 건드린 곳을 남긴다.

- 섹션 1 · 2 통과 (release 앱 켜짐 · 엔진 업데이트 · 받기 · 알림 · 앱 잠금).
- 사용자 요청으로 앱 DB를 Dart(drift)에서 네이티브(Kotlin)로 옮겼다 (D-168). 이 PR 하나에 담는다.
  - 새: `MuloDb.kt` · `LibraryDb.kt` · `DbChannel.kt`(`music_app/db`), Dart `lib/core/database/native_db.dart` · `Native*Repository`.
  - 바꿈: `FavoriteStore.kt`(LibraryDb 사용) · `DownloadEngine.kt`(곡을 DB에 직접 등록, `registered`/`ack` 제거) · `MuloEngine.kt`(채널 등록) · DI · pubspec(drift 제거) · 문서.
  - 안 건드림: 도메인 인터페이스 · 유스케이스 · 화면 · 재생 · 태그 · 받기 큐 동작.

## 확인
섹션 1(release 전용)부터:
- 빌드: `flutter build apk --release --flavor full --split-per-abi --dart-define-from-file=dart_defines.local.json`
- 설치: `adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-full-release.apk` (기기 ABI에 맞는 파일)
- 로그: `adb logcat -c` 뒤 `adb logcat -s MuloPlayback MuloNative MuloTag flutter AndroidRuntime`
- 볼 것: 앱이 켜진다 · `ClassNotFoundException` / `NoSuchMethodError` / `NoSuchMethodException` / `JsonMappingException` / `FATAL EXCEPTION` 없음 · 검색 · 설정 탭이 열린다 · 받기 한 곡이 된다 · 알림 · 잠금화면 컨트롤이 뜬다.

## 남은 일 · 질문
- 체크리스트 0번(debug 키 서명, 어댑티브 아이콘, 공유 메뉴 intent, network_security_config, Google 로그인 dart-define)은 시험하면서 필요한 것만 고친다.

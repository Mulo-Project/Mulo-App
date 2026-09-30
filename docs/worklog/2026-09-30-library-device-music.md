# 보관함 DB · 기기 음악 불러오기

- 날짜: 2026-09-30
- 분류: 앱
- 상태: 완료 (merge 대기)
- 브랜치: `feature/library-device-music` (`feature/settings-brightness` 위)
- 상세 기능: 기기 음악 불러오기 #11, 곡 목록 보기 #10 · 정렬·검색 #12 (실데이터), 커버 이미지 등록(저장)

## 한 일
- drift DB (`tracks` · `covers`), `DriftLibraryRepository`(최신순 watch, uri 중복 건너뛰기).
- 기기 음악 스캐너: Android `MediaStoreMusicScanner`(권한 + 네이티브 MediaStore 조회), 데스크톱 `DirectoryMusicScanner`(폴더 고르기 + 확장자 검색).
- `LibraryImportViewModel`: 결과(추가 n곡 · 새 곡 없음 · 권한 거절 · 실패 · 취소) → 스낵바.
- 보관함 화면: DB 데이터, 빈 상태 카드(불러오기 버튼), 상단 불러오기 버튼(진행 중 표시), "기기 n곡 · 받은 곡 m곡", 모르는 아티스트 · 앨범 문구.
- 커버 저장: `DriftCoverStore`(앱 지원 폴더로 복사, 교체 · 삭제 시 옛 파일 삭제), `CoverController`가 시작 시 불러옴.
- 재생 대기열 초기값을 비움 (가짜 곡 제거).
- 스낵바 테마 (떠 있는 둥근 알림).
- 라이트 모드 색 유리 카드 글자색 수정 (D-017).
- 테스트: 리포지토리(메모리 SQLite) 2, 커버 저장소 2, 불러오기 VM · 폴더 스캔 3, 커버 컨트롤러 저장 · 복원, 위젯(빈 보관함 → 불러오기, 곡 누르기 → 미니 플레이어). `test/helpers/fakes.dart`.

## 바꾼 설정
- `pubspec.yaml`: `drift`, `drift_flutter`, `path_provider`, `permission_handler`, dev `drift_dev` · `build_runner` · `mocktail`
- `AndroidManifest.xml`: READ_MEDIA_AUDIO, READ_EXTERNAL_STORAGE(maxSdk 32)
- `android/app/build.gradle.kts`: compileSdk 37 (permission_handler 요구)
- Kotlin: `MediaStoreChannel.kt`, `MainActivity.kt`(채널 등록)

## 확인
- `flutter analyze` 0, `flutter test` 통과, `flutter build apk --debug` 성공.
- 에뮬레이터(API 37): 직접 만든 테스트 음(wav 2개)을 Music 폴더에 넣고 → 불러오기 → 권한 허용 → "2곡을 불러왔어요", 목록 표시 → 앱 재시작 후에도 유지 ✅.

## 남은 일
- 실제 재생 (just_audio + audio_service) — 다음 브랜치.
- 데스크톱 태그 읽기, 곡 정보 수정 · 삭제(#13).

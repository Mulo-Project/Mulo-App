# 2026-11-16 release R8 크래시 수정 · 받기 엔진 자동 업데이트

- 분류: fix(build) + feat(engine)
- 브랜치: fix/release-r8-workmanager-keep (PR #176)

## 한 일
- release(R8) 시작 크래시 수정: `proguard-rules.pro`에 WorkManager/Room(`WorkDatabase_Impl`)과 commons-compress/xz/youtubedl_common keep 규칙 추가.
  - 증상 1: 앱이 켜지자마자 `NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init>`.
  - 증상 2: 검색 · 설정 탭에서 `YoutubeDL.initPython → ZipUtils.unzip → class … is not a concrete class`.
- 검색 · 설정을 열 때 yt-dlp를 켜지 않도록 `YtDlpManager.status()`가 버전을 읽지 않게 했다 (APK에 들어 있어 항상 쓸 수 있음).
- 받기 엔진(yt-dlp) 업데이트를 사용자가 몰라도 되게 함 (`EngineUpdater`):
  - 앱을 켤 때마다 검사하고 새 버전이 있으면 받는다. 인터넷이 없으면 조용히 건너뛴다.
  - 받기가 "버전이 오래됐다"는 yt-dlp 오류로 실패하면 snackbar로 알리고 바로 업데이트한다 (1시간 안에는 반복하지 않음).
  - 설정의 "다운로드 엔진" 줄(설치 · 업데이트 버튼)을 없앴다.
- 문구 `downloadEngineOutdated` 추가 (ARB + 생성 파일 손으로 반영, `flutter gen-l10n`으로 같은 결과여야 함).

## 확인 필요 (클라우드에서는 빌드 · 테스트 불가)
- `flutter analyze` · `flutter test` · release(full) 빌드 후 실기기에서 검색 · 설정 탭이 열리는지.

## 추가 (같은 PR)
- 앱 데이터를 지운 뒤 불러오기에서 `Movies/Mulo`의 받아 둔 영상이 돌아오지 않던 문제: 불러오기가 영상 기본 폴더(`LoadedFolderRepository.defaultVideoFolder`)도 읽는다.
- 웹에서 고른 커버가 곡 파일에 안 쓰이던 문제: 곡 정보 화면에서 커버를 고르면 `EmbedTrackCover`가 커버(웹 이미지 · 기기 사진, 확대 · 위치)를 파일 태그에 쓴다. 이전에는 앱 DB에만 저장돼, 앱 데이터를 지운 뒤 불러오면 처음 받을 때의 썸네일이 보였다.
  - 커버를 지우는 경우는 파일에서 이미지를 빼지 못해 이번에는 쓰지 않는다.
- 다운로드 모드 줄 제거, 웹 커버 고르기 중복 pop으로 검은 화면 남던 문제 수정.

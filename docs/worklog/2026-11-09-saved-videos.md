# 저장한 음원 + PiP 수정 (2026-11-09)

D-157 · D-158.

## 변경
- Android `StreamCache`: 저장 저장소(`saved_streams`, 지우지 않음) · 저장 id별 경로 분기 · 통째로 받기(`CacheWriter`) · 지우기. `PreviewChannel`: `setSaved` · `saveStream` · `removeSaved`, `saved` 이벤트.
- Dart(search): `SavedVideo` · `SavedVideoRepository`(prefs) · 유스케이스(`LoadSavedVideos` `SaveVideo` `RemoveSavedVideo` `MarkSavedVideoReady` `WatchSavedDone`) · `SavedVideosCubit`(앱 전체) · `SavedVideosScreen`(`/search/saved`). 영상 상세 상단에 `저장` 버튼, 검색 화면 상단에 `저장한 영상` 버튼.
- PiP: 소리 섞인 형식 미리 듣기에서 재생 상태 연결 누락을 고침, 비율 하한 · 예외 처리.
- 문구: ko/en ARB와 생성 파일을 손으로 같이 고침 (클라우드라 `flutter gen-l10n` 못 돌림).

## 추가 (같은 PR, 사용자 요청)
- 저장 대상을 음원 기준으로(사운드클라우드 포함), 유튜브는 저장 때 화질 선택. 저장한 곡 줄 → 상세 화면, 구독 새 영상 줄 `>` 버튼 → 상세 화면. 영상 전체 화면 버튼(상세 · 플레이어).

## 확인 필요 (클라우드라 빌드 · 테스트 못 함)
- PC: `flutter gen-l10n`(차이 없는지), `dart format`, `flutter analyze`, `flutter test`, Android 빌드.
- 기기: 상세에서 저장 → 받는 중 → 저장한 영상에서 재생, 비행기 모드(주소 읽기 불가)는 재생 안 됨이 정상, 저장 해제 후 용량 감소, 임시 저장소 비우기가 저장한 영상을 안 지우는지, 영상 재생 중 홈 → 작은 창 · 재생/일시정지 버튼, 화질 시트 후 저장 → 들을 때 네트워크 없이 시작하는지, 전체 화면 진입 · 복귀(가로 → 세로), 새 영상 시트 `>` → 상세.

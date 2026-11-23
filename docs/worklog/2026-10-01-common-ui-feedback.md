# 공통 UI 피드백 반영

- 날짜: 2026-10-01
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `ui/common-feedback` (`feature/local-lyrics` 위, PR #24 다음)
- 상세 기능: 공통 (사용자 피드백 2026-10-01)

## 한 일
- **카드 줄이기**: 카드(유리 면)는 보관함 · 재생목록에만 남기고, 홈(오늘 · 통계 · 빈 상태) · 검색(재생목록 헤더 · URL 결과 · 빈 상태) · 보관함 빈 상태 · 설정 묶음(`SectionCard`)은 면 없이 제목 · 본문 · 구분선으로 바꿨다.
- **미니 플레이어**: 가로 전체 너비 · 모서리 직각 (`AppShell`의 바깥 여백 제거, `MiniPlayerBar` 모양).
- **테마 미리보기**: 설정 › 테마의 한 줄 → `ThemePreviewScreen`(별도 화면, 최상위 내비게이터라 하단 탭 · 미니 플레이어가 가려진다).
- **PIN 화면**: `PinEntryScreen.open`을 최상위 내비게이터로 열어 하단 탭 · 미니 플레이어를 가린다.
- **곡 메뉴 → 팝업 메뉴**: 바텀 시트 대신 `showAppMenu`(디자인 시스템 `app_popup_menu.dart`). ⋮는 버튼 옆, 길게 누르기 · 오른쪽 클릭은 눌린 자리에 뜬다 (`TrackTile.onMenu(Offset)`).
- **커버 이미지 변경 위치**: 전체 화면 플레이어 커버의 편집 버튼 · 누르기 제거. 곡 타일 팝업 메뉴에서만 바꾼다.
- **삭제 = 파일까지 삭제**: `DeleteTrack`이 `TrackFileRepository`로 음악 파일을 먼저 지우고 성공해야 기록을 지운다. 못 지우면 기록은 그대로 두고 안내.
  - Android: `MediaStoreChannel.deleteAudio` (바로 삭제 → 실패 시 시스템 삭제 동의 창, 11+ `createDeleteRequest` · 10 `RecoverableSecurityException`). `MainActivity.onActivityResult`로 결과를 받는다. 데스크톱: `File.delete`.
- **재생목록 안의 곡 메뉴**: 삭제가 "재생목록에서 빼기"(`PlaylistRepository.removeTrack`) / "파일 삭제"로 나뉜다 (`showTrackMenu(playlistId:)`).

## 바꾼 설정
- `AndroidManifest.xml`: `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion=28`) 추가 — Android 9 이하에서 파일 삭제용.
- Kotlin: `MediaStoreChannel`(deleteAudio, 생성자에 Activity 제공자), `MainActivity`(onActivityResult).
- 새 패키지 · 에셋 없음. drift 스키마 변경 없음.
- 문구(ko · en): `settingsThemePreview`(이름 변경) · `settingsThemePreviewDesc` · `trackMenuRemoveFromPlaylist` · `trackMenuDeleteFile` · `trackRemovedFromPlaylist` · `trackDeleteFailed`, `trackDeleteBody` · `trackDeleted` 수정.

## 확인
- `flutter analyze` 0, `flutter test` 통과, `flutter build apk --debug` 성공 (flavor는 아직 없음).
- 새 · 바뀐 테스트: 팝업 메뉴(⋮ · 길게 누르기 · 오른쪽 클릭), 삭제 시 파일 삭제 · 실패 시 기록 유지, 재생목록 안 메뉴(빼기 · 파일 삭제), 재생목록 `removeTrack`, 미니 플레이어 가로 전체 · 직각, 테마 미리보기 별도 화면, PIN 화면에서 하단 탭 숨김.
- 에뮬레이터 · 실기기 확인은 하지 않았다. 특히 Android 삭제 동의 창(10 · 11+)은 실기기 확인이 필요하다.

## 남은 일 · 질문
- 재생목록 상세(곡 목록) 화면이 아직 없어 "재생목록 안의 곡 메뉴"를 부르는 화면은 없다. 상세 화면을 만들 때 `playlistId`를 넘기면 된다.
- 재생 중인 곡을 삭제하면 대기열에서만 빼고 재생은 이어진다 (이전과 동일).

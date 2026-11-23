# 검색 · 다운로드 다듬기

- 날짜: 2026-10-02
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `feature/search-download-polish` (`feature/cover-colors` 위, PR #30 다음)
- 상세 기능: 저장 위치 (#23) · 다운로드 대기열 (#7) · 공통 (사용자 피드백 2026-10-02, 2/3)

## 한 일
- 유튜브 아이콘의 재생 삼각형을 항상 흰색으로 (`YoutubeMark`), 웹 아이콘은 다크 흰색 · 라이트 연한 회색.
- 다운로드 목록: 썸네일 배경 카드 대신 얇은 테두리 카드 + 곡 타일(앞에 이미지). 대기 · 일시정지 글자 제거.
- 설정 "저장 위치"가 기본 다운로드 경로가 된다 (폴더 선택기). 받기 팝업은 이 경로로 채워 시작하고 곡마다 고칠 수 있다.
- 받기 팝업 장르 칸 아래에 기존 장르 제안 (누르면 채움).
- 구조: `DownloadSettingsRepository` · 유스케이스 3개 · `DownloadSettingsCubit`, `DownloadRequest.savePath`, `defaultMusicFolder()` 공통화.

## 바꾼 설정
- 새 패키지 · 에셋 · 네이티브 변경 없음 (file_picker · shared_preferences는 이미 사용 중). 스키마 변경 없음.
- 문구(ko · en): `downloadFieldSavePath` · `downloadGenreExisting` · `downloadPickFolder` · `settingsSavePathDesc` 추가, `statusQueued` · `statusPaused` 삭제.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (저장 위치 설정 · 취소 · 장르 제안 · 받기 팝업 저장 위치 테스트). 스크린샷으로 검색 탭 레이아웃 확인.

## 남은 일 · 질문
- 웹 아이콘 색은 "다크 흰색 / 라이트 연한 회색"으로 해석했다 (라이트 배경에서 흰색은 안 보여서). 반대 의도였다면 알려 주세요.
- 저장 위치를 바꿔도 보관함의 "불러오는 폴더" 기본 폴더는 따라가지 않는다 (아직 `Music/Mulo` 고정).
- 실제 파일 저장은 다운로드 엔진이 붙을 때 `savePath`를 쓴다.

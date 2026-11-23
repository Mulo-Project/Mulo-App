# 가사 보기 테마 (목록 · 가운데 한 줄 · 커버 배경)

- 날짜: 2026-10-16
- 분류: 앱
- 상태: 진행 중 (브랜치 `feature/lyric-sync-extras`에서 시간 보정 · 유튜브 자막 가져오기와 함께 PR 예정)
- 브랜치 · 커밋: `feature/lyric-sync-extras`

## 한 일
- 가사 보기에 테마 3가지: 목록(기존), 가운데 한 줄(현재 줄이 가운데에 크게, 앞뒤 3줄까지 흐리게, 줄이 바뀌면 부드럽게 미끄러짐), 커버 배경(커버를 한 번만 흐려 아주 옅게 깔고 어둡게 덮음).
- 가사 보기 아래 줄의 `테마` 버튼(현재 테마 이름 표시)으로 바꾸고, 고른 값은 shared_preferences(`lyrics.theme`)에 저장한다.
- `LyricsSettings`(테마 + 지금 반응 시간 보정 기본값) · `LyricsSettingsCubit` · 저장소 · 유스케이스를 추가했다. 시간 보정 작업이 같은 설정을 쓴다.
- 줄마다 BackdropFilter를 쓰지 않고, 카드 없이 그린다.

## 바꾼 설정
- pubspec · Gradle · Manifest 변경 없음.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과. 실제 기기에서 애니메이션 확인은 아직.

## 남은 일 · 질문
- 가운데 한 줄은 싱크된 가사에만 적용된다 (일반 글 가사는 목록 그대로).

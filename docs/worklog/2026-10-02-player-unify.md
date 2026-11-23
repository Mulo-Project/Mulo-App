# 재생 화면 하단 통일 · 커스텀 모양

- 날짜: 2026-10-02
- 분류: 앱 · 디자인
- 상태: 완료
- 브랜치 · 커밋: `ui/player-polish`
- 상세 기능: 미니·전체 화면 플레이어 (#19)

## 한 일
- 음반 모양 삭제, 커스텀(뉴모피즘) 모양 추가 (`PlayerStyle.custom`).
- 하단 조작부를 `PlayerControls`로 통일 (모든 기능 아이콘 유지). 결정 기록: D-041.

## 바꾼 설정
- 없음 (패키지 · 네이티브 변경 없음). ARB: `playerStyleVinyl` 삭제, `playerStyleCustom` 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (모든 모양에 기능 아이콘 확인 테스트).
- 스크린샷: `player-custom`, `player-arc` 등.

## 남은 일 · 질문
- 커스텀의 라이트 모양, 커버 사진이 있을 때 실제 모습은 기기에서 확인 필요.

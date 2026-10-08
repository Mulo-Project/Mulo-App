# 하단 받기 진행 줄 · 미리 듣기 미니 플레이어 통합

- 날짜: 2026-10-08
- 분류: 앱 · 디자인
- 상태: 진행 중 (PR 확인 대기)
- 브랜치 · 커밋: `feature/bottom-download-bar`
- 상세 기능: 다운로드 진행 표시 · 미리 듣기

## 한 일
- `DownloadBar`(앱 셸, 미니 플레이어 위): 한 줄 요약 + 눌러서 펼쳐지는 대기 목록. 검색창 아래 받기 카드 제거 (`download_progress_card.dart`는 곡 줄 도우미만 남겨 `download_item_widgets.dart`로 이름 변경).
- 미리 듣기 줄(`PreviewMiniBar`) 제거. 미리 듣는 동안 미니 플레이어가 미리 듣는 곡으로 바뀌고, 누르면 그 곡 상세 화면. 메인 대기열은 그대로.
- `MiniPlayerBar`에 `showSkip`, `queueIcon` 추가. ARB에 `downloadsRemaining` 추가.
- 결정: D-092.

## 바꾼 설정
- 없음 (ARB 문구만 추가).

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과 (받기 · 미리 듣기 테스트를 새 동작에 맞춰 고침).

## 남은 일 · 질문
- 실기기에서 펼침 높이(화면의 40%)와 미리 듣기 전환 모습 확인.

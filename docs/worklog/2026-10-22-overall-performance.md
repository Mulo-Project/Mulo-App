# 전체 성능 개선

- 날짜: 2026-10-22
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `chore/overall-performance`
- 상세 기능: 공통 작업 (성능)

## 한 일
- 보관함 아티스트 · 앨범 · 장르 탭을 `SliverList.builder`로 지연 생성 (줄 수천 개여도 탭 전환이 가볍게).
- 가사 전체화면이 재생 위치 틱마다 다시 그려지던 것을 곡 변경 때만 그리도록 `context.select`로 축소.
- 이미 처리된 항목 확인: 곡 줄 구독 축소 · 리스트 위 BackdropFilter 제거(#110), 미니 플레이어 · 플로팅 버튼 buildWhen.

## 바꾼 설정
없음.

## 확인
`flutter analyze` 경고 0, `flutter test` 통과.

## 남은 일 · 질문
- 시작 시 cubit 19개 생성(앱 전체 MultiBlocProvider)은 실기기 측정 후 판단.

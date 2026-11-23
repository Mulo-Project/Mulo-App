# 재생목록 카드 순서 바꾸기

- 날짜: 2026-10-23
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `feature/playlist-reorder` (기반: `chore/overall-performance`)
- 상세 기능: 재생목록 관리 (공통)

## 한 일
- 재생목록 탭 위 막대에 "순서 바꾸기"(직접 만든 재생목록이 둘 이상일 때)를 추가하고, 길게 눌러 끌어 옮기는 화면(`PlaylistReorderScreen`)을 만들었다. 옮기면 바로 저장되고 카드가 그 순서로 놓인다. 좋아요 목록은 늘 맨 앞이라 움직이지 않는다.
- 순서는 DB `playlists.sort_order`에 저장한다 (D-122). 새 재생목록은 맨 뒤로 간다.

## 바꾼 설정
- drift 스키마 10 → 11 (`playlists.sort_order` 열 추가, 기본 0). `app_database.g.dart` 재생성.

## 확인
`flutter analyze` 경고 0, `flutter test` 통과 (저장소 · 화면 끌기 테스트 추가).

## 남은 일 · 질문
- 카드를 재생목록 탭에서 바로 끌어 옮기는 방식은 하지 않았다 (두 열 격자라 끌기가 어렵다). 필요하면 후속.

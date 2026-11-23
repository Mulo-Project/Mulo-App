# 앱 성능 개선 (1차)

- 날짜: 2026-10-08
- 분류: 앱
- 상태: 진행 중 (1차 완료, 프로파일링 후 추가)
- 브랜치 · 커밋: `chore/app-performance`
- 상세 기능: 공통 작업

## 한 일
- 보관함 곡 탭: `ListView(children)`로 곡을 전부 만들던 것을 `CustomScrollView` + `SliverList.builder`로 바꿔 보이는 줄만 만든다.
- 곡 줄(`TrackListTile`): 재생 곡 전체를 구독하던 것을 "이 곡인지"(bool)만 고르게 해서, 곡이 바뀔 때 두 줄만 다시 그린다.
- 목록 위 헤더의 원형 버튼 · tonal 알약 버튼은 `blur: 0` (단색 배경 위라 흐림이 보이지 않고, 스크롤마다 BackdropFilter 비용만 든다).

## 바꾼 설정
- 없음.

## 확인
- `flutter analyze` 경고 0, `flutter test` 전체 통과.

## 남은 일 · 질문
- `flutter run --profile` + DevTools로 실제 병목 확인 (하단 미니 플레이어 · 받기 줄 유리, 틱마다 rebuild).
- 검색 · 재생목록 상세 · 앨범 · 아티스트 화면의 목록 lazy 렌더링.

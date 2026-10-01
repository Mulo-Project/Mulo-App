# 홈 4구역 · 청취 통계 피드백

- 날짜: 2026-10-01
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `feature/home-stats-feedback` (`fix/search-download-ui-feedback` 위, PR #27 다음)
- 상세 기능: 청취 분석 · 많이 들은 곡 순위 · 추천 목록 · 최근 재생

## 한 일
- 홈을 구역별 레이아웃의 4구역으로 구성 (D-035): 최근 들은 곡(굵은 머리말 + 10곡 목록, 접기), 재생 기록(칩 + 그래프, 월간 년/월 팝업 메뉴, 전체는 큰 숫자), 많이 들은 곡(1·2·3등 시상대 + 10곡, 접기), 추천(PageView, 페이지마다 10곡).
- 꺾은선 그래프 `AppLineChart`만 디자인 시스템에 추가. 나머지는 홈 전용 위젯 (`lib/features/home/presentation/widgets/`).
- 앱 가입일 저장 (`JoinDateRepository`), 월간 선택은 가입한 달부터.
- 도메인: 기간 선택 제거, `HomeSummary.days` + `range()`, 아티스트 · 장르 순위에 곡 목록, 추천 후보 확대(오랜만에 다시 듣기 추가).
- 많이 들은 곡 상세 `/home/top-tracks` (TOP 100, 전체 재생).

## 바꾼 설정
- 새 패키지 · DB 스키마 · 네이티브 변경 없음. 문구(ARB ko/en) 추가, `homeRecent` · `homeRecommendations` 문구 변경, shared_preferences 키 `app.joinedAt` 추가.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (도메인 · bloc 테스트 갱신). 홈 전체 스크린샷(`home-full`)으로 4구역 확인.

## 남은 일 · 질문
- 월간 달력의 "가입일"은 계정이 없어서 첫 실행 날짜다.

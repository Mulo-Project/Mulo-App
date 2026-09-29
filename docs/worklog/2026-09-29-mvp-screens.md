# MVP 화면 퍼블리싱 · 글래스 스타일 (자리 표시 데이터)

- 날짜: 2026-09-29
- 분류: 디자인 · 앱
- 상태: 진행 중 (사용자 확인 · 피드백 대기)
- 브랜치: `ui/mvp-screens` (디자인 시스템 커밋 포함 → PR 하나로 develop에)
- 상세 기능: 곡 목록 보기 #10 · 정렬·검색 #12 · 기기 음악 불러오기 #11 · 재생목록 관리 #20 · 유튜브 재생목록 가져오기 #22 · URL로 곡 정보 불러오기 #1 · 키워드 검색 #2 · 재생목록 URL 불러오기 #3 · 공유 메뉴로 받기 #4 · 음질 선택 #6 · 중복 다운로드 방지 #9 · 다운로드 대기열 #7 · 서버 연결·모드 선택 #31 · 저장 위치 #23 · 기본 음질·포맷 #24 · 엔진 업데이트 #25 · 알림 곡 정보 숨기기 #32 · 미니·전체 화면 플레이어 #19 · 기본 재생 컨트롤 #14 · 셔플·반복 #15 · 재생 대기열 #16

## 한 일
- 설정: `go_router`, `flutter_localizations` + `intl`, gen-l10n (`l10n.yaml`, ARB ko · en 95개 문구). D-009, D-010.
- 공통 컴포넌트 추가: AppTopBar, AppBottomNav, AppSearchField, ArtworkBox(`toneFor`), TrackTile, AppSwitch, SectionCard · SettingRow, SegmentedPills · StatusPill.
- 앱 틀: 하단 탭 5개(보관함 · 재생목록 · 검색 · 다운로드 · 설정) + 미니 플레이어, 전체 화면 플레이어는 아래에서 올라옴.
- 화면(가짜 데이터, 화면 안에서만 상태 변경):
  - 보관함: 곡 수 카드 · 전체 재생 · 셔플, 곡/아티스트/앨범, 검색, 이름·추가일·아티스트 정렬, 누르면 재생
  - 재생목록: 새 재생목록 · 유튜브 가져오기, 색 유리 카드 격자
  - 검색: 빈 상태 안내, URL → 곡 카드(음질 · 받기), 재생목록 URL → 곡 고르기, 검색어 → 결과 20개(이미 받은 곡 표시). `/search?q=`로 채워 열기
  - 다운로드: 진행 중 수 · 전체 진행률 원, 상태별(받는 중 · 대기 · 일시정지 · 실패 · 완료) 줄
  - 설정: 서버 · 다운로드 · 엔진 · 재생 · 테마(곡 분위기 따라가기, 테마 색 기본/코랄 — 실제로 바뀜, 디자인 미리보기) · 정보
  - 플레이어: 커버 카드, 시간, 탐색 막대(누르기 · 끌기), 셔플 · 이전 · 재생 · 다음 · 반복, 대기열 시트
- `NowPlayingViewModel`(Riverpod): 재생/일시정지, 다음/이전(3초 규칙), 탐색, 셔플, 반복 순환, 대기열 이동 — 단위 테스트 7개.
- 스크린샷 테스트 `test/screenshots/` (기본 건너뜀), 한 · 영 × 9화면. D-011.
- **글래스 스타일로 변경 (D-012, 사용자 피드백 "도트가 아니라 글래스 느낌")**
  - 삭제: DotGridBackground, DotMatrixText, DottedProgressArc/Bar, GlowCard
  - 추가: AppBackground(검정 + 테마 색 빛), GlassSurface · GlassCard(흐림 + 반투명 + 빛 테두리), StatNumber, ProgressRing · ProgressLine
  - 유리로 바꿈: PillButton(tonal · outline), CircleIconButton, MiniPlayerBar, AppBottomNav(떠 있는 바), SectionCard, AppSearchField, SegmentedPills, AppSwitch
  - 팔레트: `dotGrid` → `glassFill` · `glassBorder` · `glassHighlight`, `AppGlass`(흐림 24, 채움 불투명도)
  - 앱 틀 `extendBody`: 내용이 미니 플레이어 · 탭 바 뒤로 흘러 유리에 비침

## 바꾼 설정
- `pubspec.yaml`: `go_router ^18.0.2`, `flutter_localizations`, `intl ^0.20.3`, `flutter.generate: true`
- `l10n.yaml`, `dart_test.yaml`(screenshot 태그)

## 확인
- `flutter analyze` 0, `flutter test` 전체 통과 (위젯 3 + ViewModel 7 + 기타)
- 스크린샷 한 · 영 확인 (영어 긴 문구 넘침 2곳 수정)
- 에뮬레이터(API 37)에서 글래스 흐림 · 빛 확인 (테스트 스크린샷은 그림자가 딱딱하게 나옴 — 테스트 렌더 한계)

## 남은 일 · 질문
- 사용자 확인 · 피드백 → 반영 → develop merge (승인 후)
- 다음 기능 연결 후보: 플레이어(#14 · #19 · #17, just_audio + audio_service), 보관함 저장소(drift)

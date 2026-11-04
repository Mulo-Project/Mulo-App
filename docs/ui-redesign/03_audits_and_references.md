# 03. 감사 방법 · 참고 앱

## 테마 감사 (8 프리셋 × 다크/라이트 = 16)
프리셋: violet · coral · ocean · forest · sunset · rose · gold · ice (`theme_source/theme_presets.dart`).
1. **토큰 수집**: 테스트 코드에서 `ThemePreset.values × Brightness`로 `paletteFor()`를 호출해 실제 resolve된 `AppPalette`를 표(CSV/MD)로 덤프. 눈대중 값 금지.
2. **대비 계산**: `core/design/contrast.dart`의 `contrastRatio`로 계산. 조합: onSurface/background·surface, onSurfaceMuted/background·surface, primary·accent / background·surface, onPrimary/primary, onAccent/accent, outline/surface·background, glassFill/glassBorder 위 글자, 커버 위 `onGlow` 글자.
3. **기준**: 일반 글자 4.5:1, 큰 글자 3:1, 의미 있는 비텍스트 3:1 (WCAG 2.2 AA 참고). 실제 크기 · 굵기 · 사용처에 맞춰 해석. 숫자만으로 끝내지 않고 선택/눌림/비활성/오류 상태 구분과 색 균형(코랄 primary·accent 경쟁, 로즈 유사색, 선셋 온도 유사, 골드/아이스 밝은 색, 바이올렛 라임 면적)을 캡처로 확인 — 현재는 가설이며 결함으로 단정하지 않는다.
4. **고정 브랜드색**(YouTube 빨강, SoundCloud 주황)은 테마와 분리 확인.
5. **문서-코드 불일치** 목록화 (라이트 3:1 vs 7:1 서술 등). 토큰 값 변경은 제안 + 예상 영향 + 검증 방법까지만.
6. 캡처 매트릭스(가능할 때): Home · Library · Search · Player(Square) · Settings 테마 섹션 × 16.

## Dialog / Sheet / Menu / Overlay 감사
각 항목을 한 행으로: 트리거(화면/버튼) → 표시 UI(Dialog/Sheet/Menu/Overlay/Route) → 사용자 선택 → 닫힘 · 반환값 → 호출 화면 후속 동작.
추가 점검: 높이(최대 비율)·스크롤·SafeArea·키보드·버튼 고정, 취소/바깥 탭 동작, 파괴적 동작 표시, 한 줄/세로 버튼 전환 조건.
형태 적합성 원칙: 짧은 선택/설정 = Sheet, 짧은 확인/입력 = Dialog, 긴 편집 = 별도 화면(복잡한 import · 다운로드 화면을 Dialog로 축소하지 않음). 인벤토리는 `01_inventory.md` §3.

## 참고 앱 (패턴 단위로만 인용)
| 앱 | 볼 것 | Mulo 대응 |
|---|---|---|
| Spotify | Now Playing/Queue 접근, 행 정보 위계, 주/보조 버튼 차이 | TrackTile, MiniPlayerBar, PlayerControls, Queue |
| Apple Music | 보관함 분류 · 검색, Playing Next, 앨범/아티스트 표현 | Library, TrackGroupScreen, PlaylistDetail, Queue |
| YouTube Music | 썸네일/채널 메타데이터, 다운로드 구분, 필터 | Search, MediaDetail, Subscriptions, 가져오기 |
| Poweramp | 플레이어 스킨 다양성, EQ 컨트롤 밀도 | Square/Full Bleed/Arc, Equalizer, player style sheet |
| Material 3 | 버튼 · 다이얼로그 · 시트 · 선택 상태 · 대비 원칙 | AppDialog, showAppSheet, 상태 표현 (위젯 교체 아님) |

각 항목 기록: 제품/버전/플랫폼/확인일 · 관찰한 패턴 · 해결하는 문제 · Mulo 대응 · 적용/부분/부적합 · 출처 URL. 최신 UI는 접근 가능한 공식 자료로 확인하고, 이미지 한 장으로 단정하지 않는다. 로고 · 아이콘 · 브랜드색 · 고유 화면은 복제하지 않는다. 스트리밍 전용 기능은 가져오지 않는다 (Mulo = 로컬 보관함 + 플레이어 + 검색/다운로드 + 구독).
이번 단계에서는 외부 조사를 하지 않았다 (실행 순서 2~4에서 수행).

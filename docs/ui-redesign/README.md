# UI/UX 리디자인 계획

> 상태: **계획 단계**. 이 폴더는 문서만 담는다. production Dart 코드 · 토큰 · 동작은 바꾸지 않았다.
> 기준: `develop` @ `9aa8172` (#155). 원본 요청: 사용자 UI/UX 리디자인 마스터 명세서(부록 A·B 포함).
> 이번 단계 결정: 스크린샷 · 주석 이미지 · 와이어프레임은 만들지 않는다. 계획만 정리한다.

## 목표
기능 · API · 진입 경로를 그대로 두고 (1) 페이지 배치와 (2) 공통 컴포넌트 외형을 개선한다.
다른 앱을 복제하지 않고, 어떤 테마(8종 × 다크/라이트)에서도 색과 조작이 자연스럽게 보이게 한다.

## 지켜야 할 규칙 (프로젝트 디자인 규칙)
- 색 `context.palette`, 간격 `AppSpacing`(4pt), 반경 `AppRadii`(기본 12), 크기 `AppSizes`, 아이콘 `AppIcons`. `Color(0x…)`/`Colors.xxx` 금지.
- Pretendard, 기본 다크(검정 + 바이올렛 #7D39EB + 라임 #C6FF33).
- 카드/박스를 늘리지 않는다 (`docs/design-system.md`: 카드는 보관함 · 재생목록 한정). TrackTile은 행형 유지.
- 유리(Glass)는 목록 행 · 움직이는/겹치는 면에 쓰지 않는다 (`GlassSurface(solid: true)`).
- 선택지(picker)는 바텀 시트(`showAppSheet`), 짧은 확인은 `AppDialog`, 긴 편집은 별도 화면.
- 컴포넌트 변경은 공개 API · 콜백 · 기존 variant 유지. 새 필요는 variant 추가로.

## 문서
| 파일 | 내용 |
|---|---|
| [01_inventory.md](01_inventory.md) | 화면 · 공통 컴포넌트 · Dialog/Sheet/Menu/Overlay 인벤토리 (실제 코드 기준) |
| [02_tracks_and_roadmap.md](02_tracks_and_roadmap.md) | Track A/B 구분, P0/P1/P2 로드맵, 실행 순서(작업 단위) |
| [03_audits_and_references.md](03_audits_and_references.md) | 테마 감사 방법, overlay 감사 방법, 참고 앱 조사 방법 |
| [04_open_questions.md](04_open_questions.md) | 사용자에게 물을 것 |

## 진행 원칙
- 한 작업 단위 = 한 브랜치 = 한 PR (PR 쪼개지 않음).
- 레이아웃(Track A) 승인과 컴포넌트 외형(Track B) 승인은 **따로** 받는다. 한쪽 승인이 다른 쪽 승인이 아니다.
- 실제 캡처가 필요한 근거(밀도, 640px 화면 등)는 사용자가 PC에서 `flutter test --run-skipped -t screenshot test/screenshots`를 돌릴 수 있을 때 보강한다. 현재 클라우드 작업에서는 빌드 · 캡처를 못 하므로 모든 판단은 **코드 기반 추정**이다.
